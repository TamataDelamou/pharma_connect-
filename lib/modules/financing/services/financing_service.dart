import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/financing_request.dart';
import '../models/financing_repayment.dart';
import '../models/credit_score.dart';

class FinancingService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Credit Score ----

  Future<CreditScore?> getCreditScore(String pharmacyId) async {
    try {
      final response = await _client
          .from('credit_scores')
          .select()
          .eq('pharmacy_id', pharmacyId)
          .maybeSingle();
      if (response == null) return null;
      return CreditScore.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load credit score: $e');
    }
  }

  /// Recalcule le score à partir de données réelles de la plateforme
  /// (audit Module 14, 29/08/2026) — remplace l'ancien score aléatoire
  /// (`600 + millisecondsSinceEpoch % 400`) qui ne reflétait rien de
  /// l'activité de l'officine. Trois facteurs, chacun sur 0-100, combinés
  /// en un score sur 1000 (poids : historique de remboursement 50%, volume
  /// B2B 30%, ancienneté du compte 20% — le remboursement pèse le plus car
  /// c'est le signal le plus direct de solvabilité pour un crédit déjà
  /// accordé) :
  /// - Historique de remboursement : % d'échéances soldées à temps
  ///   (`paid`, jamais passées par `overdue`) sur l'ensemble des échéances
  ///   déjà échues, tous financements confondus pour cette officine. Une
  ///   officine sans historique (aucune échéance échue) reçoit un score
  ///   neutre de 70/100 plutôt que 0 — elle ne doit pas être pénalisée
  ///   comme un mauvais payeur simplement parce qu'elle n'a jamais encore
  ///   emprunté.
  /// - Volume B2B : nombre de commandes B2B (en tant qu'acheteuse) sur les
  ///   12 derniers mois, plafonné à 100 pour 50 commandes ou plus.
  /// - Ancienneté du compte : `pharmacies.created_at`, plafonnée à 100 pour
  ///   24 mois ou plus.
  Future<CreditScore> calculateCreditScore(String pharmacyId) async {
    final now = DateTime.now().toUtc();

    // --- Historique de remboursement ---
    final requestRows = await _client
        .from('financing_requests')
        .select('id')
        .eq('pharmacy_id', pharmacyId);
    final requestIds = (requestRows as List)
        .map((r) => r['id'] as String)
        .toList();

    int duePaidOnTime = 0;
    int dueTotal = 0;
    if (requestIds.isNotEmpty) {
      final repaymentRows = await _client
          .from('financing_repayments')
          .select('status')
          .inFilter('financing_request_id', requestIds)
          .neq('status', 'pending');
      for (final r in repaymentRows as List) {
        dueTotal++;
        if (r['status'] == 'paid') duePaidOnTime++;
      }
    }
    final paymentHistoryScore = dueTotal == 0
        ? 70.0
        : (duePaidOnTime / dueTotal) * 100;

    // --- Volume B2B (acheteuse, 12 derniers mois) ---
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final b2bOrders = await _client
        .from('b2b_orders')
        .select('id')
        .eq('buyer_pharmacy_id', pharmacyId)
        .gte('created_at', oneYearAgo.toIso8601String());
    final b2bOrderCount = (b2bOrders as List).length;
    final volumeScore = (b2bOrderCount / 50 * 100).clamp(0, 100).toDouble();

    // --- Ancienneté du compte ---
    double ageScore = 0;
    int ageMonthsRounded = 0;
    final pharmacyRow = await _client
        .from('pharmacies')
        .select('created_at')
        .eq('id', pharmacyId)
        .maybeSingle();
    if (pharmacyRow != null && pharmacyRow['created_at'] != null) {
      final createdAt = DateTime.parse(pharmacyRow['created_at'] as String);
      final ageMonths = now.difference(createdAt).inDays / 30;
      ageScore = (ageMonths / 24 * 100).clamp(0, 100).toDouble();
      ageMonthsRounded = ageMonths.round();
    }

    // Pondération sur 100, puis mise à l'échelle x10 pour retomber sur la
    // plage 0-1000 de la colonne `credit_scores.score`.
    final score100 =
        paymentHistoryScore * 0.5 + volumeScore * 0.3 + ageScore * 0.2;
    final int score = (score100 * 10).round().clamp(0, 1000).toInt();
    final rating = _getRating(score);

    final credit = CreditScore(
      id: _uuid.v4(),
      pharmacyId: pharmacyId,
      score: score,
      rating: rating,
      lastUpdated: now,
      factors: {
        'payment_history': paymentHistoryScore.round(),
        'b2b_volume_12m': b2bOrderCount,
        'account_age_months': ageMonthsRounded,
      },
      createdAt: now,
      updatedAt: now,
    );

    await _client
        .from('credit_scores')
        .upsert(credit.toJson(), onConflict: 'pharmacy_id');

    return credit;
  }

  String _getRating(int score) {
    if (score >= 800) return 'excellent';
    if (score >= 700) return 'good';
    if (score >= 600) return 'fair';
    if (score >= 500) return 'poor';
    return 'bad';
  }

  // ---- Financing Requests ----

  Future<List<FinancingRequest>> getRequests({
    String? pharmacyId,
    String? status,
  }) async {
    try {
      // `repayments:repayments(...)` (audit Module 14, 29/08/2026) : PostgREST
      // exige le nom RÉEL de la table embarquée, pas un alias conceptuel —
      // la table s'appelle `financing_repayments`. Même bug que C48
      // (marketplace, `order_items` vs `b2b_order_items`), qui rejetait ces
      // requêtes avec un 400 avant ce correctif.
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('financing_requests').select(
            '*, pharmacies:pharmacy_id(name), repayments:financing_repayments(id, status)',
          );

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => FinancingRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load financing requests: $e');
    }
  }

  Future<FinancingRequest?> getRequest(String id) async {
    try {
      final response = await _client
          .from('financing_requests')
          .select(
            '*, pharmacies:pharmacy_id(name), repayments:financing_repayments(*)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return FinancingRequest.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load financing request: $e');
    }
  }

  Future<FinancingRequest> createRequest(FinancingRequest request) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = request
          .copyWith(
            id: id,
            status: 'pending',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'pharmacy_name' ||
            key == 'total_repayments' ||
            key == 'paid_repayments' ||
            key == 'pharmacies' ||
            key == 'repayments',
      );

      final response = await _client
          .from('financing_requests')
          .insert(data)
          .select()
          .single();
      return FinancingRequest.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create financing request: $e');
    }
  }

  Future<FinancingRequest> updateRequest(FinancingRequest request) async {
    try {
      final data = request
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'pharmacy_name' ||
            key == 'total_repayments' ||
            key == 'paid_repayments' ||
            key == 'pharmacies' ||
            key == 'repayments',
      );

      final response = await _client
          .from('financing_requests')
          .update(data)
          .eq('id', request.id)
          .select()
          .single();
      return FinancingRequest.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update financing request: $e');
    }
  }

  Future<FinancingRequest> updateRequestStatus(
    String id,
    String newStatus,
  ) async {
    try {
      final data = {
        'status': newStatus,
        if (newStatus == 'approved')
          'approved_at': DateTime.now().toUtc().toIso8601String(),
        if (newStatus == 'active')
          'disbursed_at': DateTime.now().toUtc().toIso8601String(),
        if (newStatus == 'completed')
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('financing_requests')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      // L'échéancier (audit Module 14, 29/08/2026) est désormais généré au
      // DÉCAISSEMENT plutôt qu'à la création de la demande : générer les
      // échéances dès la demande 'pending' calculait des dates d'échéance
      // à partir d'une date de création qui pouvait n'avoir aucun rapport
      // avec le moment où l'argent est réellement débloqué (une demande
      // peut rester en attente plusieurs semaines). `generateRepaymentSchedule`
      // écrase l'ancien échéancier s'il en existe déjà un (voir plus bas).
      if (newStatus == 'active') {
        await generateRepaymentSchedule(id);
      }

      return FinancingRequest.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }

  Future<void> deleteRequest(String id) async {
    try {
      await _client.from('financing_requests').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete request: $e');
    }
  }

  // ---- Repayments ----

  Future<List<FinancingRepayment>> getRepayments(String requestId) async {
    try {
      final response = await _client
          .from('financing_repayments')
          .select()
          .eq('financing_request_id', requestId)
          .order('due_date', ascending: true);
      return (response as List)
          .map((e) => FinancingRepayment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repayments: $e');
    }
  }

  /// [transactionId] (audit Module 14, 29/08/2026) : lie l'échéance à la
  /// transaction réelle du portefeuille GSG qui l'a soldée
  /// (`financing_repayments.transaction_id`, colonne existante mais jamais
  /// renseignée jusqu'ici — voir request_detail_screen.dart, qui appelle
  /// désormais `PaymentProvider.initiatePayment` avant ce service).
  /// `updated_by` a été retiré du payload : cette colonne n'existe pas sur
  /// `financing_repayments` (elle existe sur `financing_requests`) — la
  /// tenter ici faisait échouer chaque paiement d'échéance côté serveur.
  Future<FinancingRepayment> payRepayment(
    String repaymentId, {
    String? transactionId,
  }) async {
    try {
      final data = {
        'status': 'paid',
        'paid_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        if (transactionId != null) 'transaction_id': transactionId,
      };
      final response = await _client
          .from('financing_repayments')
          .update(data)
          .eq('id', repaymentId)
          .select()
          .single();

      // Check if all repayments are paid
      final requestId = response['financing_request_id'] as String;
      await _checkAndCompleteRequest(requestId);

      return FinancingRepayment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to pay repayment: $e');
    }
  }

  Future<void> _checkAndCompleteRequest(String requestId) async {
    final repayments = await getRepayments(requestId);
    final allPaid = repayments.every((r) => r.status == 'paid');
    if (allPaid) {
      await updateRequestStatus(requestId, 'completed');
    }
  }

  // ---- Generate Repayment Schedule ----

  Future<List<FinancingRepayment>> generateRepaymentSchedule(
    String requestId,
  ) async {
    final request = await getRequest(requestId);
    if (request == null) throw Exception('Request not found');

    // Idempotence (audit Module 14, 29/08/2026) : purge un éventuel
    // échéancier déjà présent pour cette demande avant d'en écrire un
    // nouveau, plutôt que d'accumuler des doublons si le décaissement était
    // relancé après une erreur réseau partielle.
    await _client
        .from('financing_repayments')
        .delete()
        .eq('financing_request_id', requestId)
        .eq('status', 'pending');

    final monthlyAmount = request.monthlyPayment.round();
    final repayments = <FinancingRepayment>[];
    final now = DateTime.now().toUtc();

    for (int i = 0; i < request.repaymentPeriodMonths; i++) {
      final dueDate = DateTime(now.year, now.month + i + 1, now.day);
      repayments.add(
        FinancingRepayment(
          id: _uuid.v4(),
          financingRequestId: requestId,
          dueDate: dueDate,
          amount: monthlyAmount,
          status: 'pending',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    for (final repayment in repayments) {
      await _client.from('financing_repayments').insert(repayment.toJson());
    }

    return repayments;
  }

  /// Orpheline jusqu'ici (audit Module 14, 29/08/2026) — jamais appelée
  /// nulle part, aucune échéance en retard n'était donc jamais signalée
  /// comme telle. Câblée désormais au chargement du tableau de bord
  /// (`FinancingProvider.loadRequests`, best-effort/fire-and-forget). La
  /// RLS restreint chaque officine à ses propres échéances (voir
  /// 20260829041000_financing_module_fixes.sql) : cette méthode ne marque
  /// donc jamais que les retards de l'officine actuellement connectée
  /// (ou tout retard, côté back-office). Try/catch défensif : un échec ici
  /// ne doit jamais faire échouer l'écran qui l'appelle en tâche de fond.
  Future<void> checkOverdueRepayments() async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final response = await _client
          .from('financing_repayments')
          .select()
          .eq('status', 'pending')
          .lt('due_date', today);

      for (final item in response as List) {
        await _client
            .from('financing_repayments')
            .update({'status': 'overdue'})
            .eq('id', item['id']);
      }
    } catch (_) {
      // Best-effort — voir docstring ci-dessus.
    }
  }
}
