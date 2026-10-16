import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/utils/user_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../models/cash_drawer_session.dart';
import '../models/cash_movement.dart';

/// C205 : refus du serveur sur une opération de caisse, message lisible tel
/// qu'affiché à l'utilisateur.
class CashException implements UserFacingException {
  @override
  final String message;
  const CashException(this.message);

  @override
  String toString() => message;
}

/// C205 / D62 : une session de caisse appartient à un caissier (au plus une
/// ouverte par officine). Ouverture, dépôts / retraits et fermeture passent
/// par des RPC contrôlées côté serveur ; les ventes et remboursements POS y
/// sont enregistrés automatiquement par le serveur.
class CashService {
  final _client = SupabaseService().client;

  /// Message d'erreur serveur (« CAISSE: … », sans accents) rendu lisible.
  static String serverMessage(String raw) {
    var message = raw.replaceFirst(RegExp(r'^(CAISSE|POS): '), '');
    const accents = {
      'acces refuse': 'accès refusé',
      'reserve au': 'réservé au',
      'deja': 'déjà',
      'qu\'a son nom': 'qu\'à son nom',
      'especes': 'espèces',
      'superieur': 'supérieur',
      'depots': 'dépôts',
      'compte invalide': 'compté invalide',
    };
    accents.forEach((from, to) => message = message.replaceAll(from, to));
    if (message.isEmpty) return message;
    return message[0].toUpperCase() + message.substring(1);
  }

  // ---- Sessions ----

  Future<CashDrawerSession> openSession({
    required String pharmacyId,
    required String cashierId,
    required int openingBalance,
    String? notes,
  }) async {
    try {
      final response = await _client.rpc(
        'open_cash_drawer',
        params: {
          'p_pharmacy_id': pharmacyId,
          'p_cashier_id': cashierId,
          'p_opening_balance': openingBalance,
          'p_notes': notes,
        },
      );
      final sessionId = response as String;
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session introuvable après ouverture : $sessionId');
      }
      return session;
    } on PostgrestException catch (e) {
      throw CashException(serverMessage(e.message));
    } catch (e) {
      throw Exception('Failed to open cash drawer: $e');
    }
  }

  Future<CashDrawerSession> closeSession({
    required String sessionId,
    required int closingBalance,
    String? notes,
  }) async {
    try {
      await _client.rpc(
        'close_cash_drawer',
        params: {
          'p_session_id': sessionId,
          'p_closing_balance': closingBalance,
          'p_notes': notes,
        },
      );
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session introuvable après fermeture : $sessionId');
      }
      return session;
    } on PostgrestException catch (e) {
      throw CashException(serverMessage(e.message));
    } catch (e) {
      throw Exception('Failed to close cash drawer: $e');
    }
  }

  Future<CashDrawerSession?> getSession(String id) async {
    try {
      final response = await _client
          .from('cash_drawer_sessions')
          .select('*, cashiers:cashier_id(full_name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return CashDrawerSession.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load cash session: $e');
    }
  }

  Future<List<CashDrawerSession>> getSessions({
    String? pharmacyId,
    String? cashierId,
    CashSessionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client
          .from('cash_drawer_sessions')
          .select('*, cashiers:cashier_id(full_name)');

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (cashierId != null) {
        query = query.eq('cashier_id', cashierId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }
      if (fromDate != null) {
        query = query.gte('opened_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('opened_at', toDate.toIso8601String());
      }

      final response = await query.order('opened_at', ascending: false);
      return (response as List)
          .map((e) => CashDrawerSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load cash sessions: $e');
    }
  }

  /// C205 : la caisse ouverte de l'utilisateur connecté dans cette officine
  /// (une session appartient à un caissier ; plusieurs caissiers peuvent
  /// avoir chacun leur caisse ouverte).
  Future<CashDrawerSession?> getCurrentOpenSession(String pharmacyId) async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return null;
    try {
      final response = await _client
          .from('cash_drawer_sessions')
          .select('*, cashiers:cashier_id(full_name)')
          .eq('pharmacy_id', pharmacyId)
          .eq('cashier_id', userId)
          .eq('status', CashSessionStatus.open.name)
          .maybeSingle();
      if (response == null) return null;
      return CashDrawerSession.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load current cash session: $e');
    }
  }

  // ---- Movements ----

  Future<List<CashMovement>> getMovements(String sessionId) async {
    try {
      final response = await _client
          .from('cash_movements')
          .select()
          .eq('cash_drawer_session_id', sessionId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((e) => CashMovement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load cash movements: $e');
    }
  }

  /// C205 : dépôt ou retrait d'espèces (RPC cash_add_movement). Les ventes et
  /// remboursements ne se saisissent plus ici : le serveur les enregistre avec
  /// la vente ou le remboursement POS. [referenceId] et [referenceType] sont
  /// conservés pour ne pas changer les appelants, mais ne sont plus envoyés.
  Future<CashMovement> addMovement({
    required String sessionId,
    required CashMovementType type,
    required int amount,
    String? referenceId,
    String? referenceType,
    String? notes,
  }) async {
    if (type != CashMovementType.deposit &&
        type != CashMovementType.withdrawal) {
      throw const CashException(
        'Seuls les dépôts et retraits se saisissent à la main.',
      );
    }
    try {
      final id =
          await _client.rpc(
                'cash_add_movement',
                params: {
                  'p_session_id': sessionId,
                  'p_type': type.name,
                  'p_amount': amount,
                  'p_notes': notes,
                },
              )
              as String;
      final response = await _client
          .from('cash_movements')
          .select()
          .eq('id', id)
          .single();
      return CashMovement.fromJson(response);
    } on PostgrestException catch (e) {
      throw CashException(serverMessage(e.message));
    } catch (e) {
      throw Exception('Failed to add cash movement: $e');
    }
  }

  /// C273 (b) : le compte connecté est-il le titulaire de [pharmacyId] ?
  /// (`is_pharmacy_manager`, même règle que le serveur.)
  Future<bool> isPharmacyManager(String pharmacyId) async {
    final result = await _client.rpc(
      'is_pharmacy_manager',
      params: {'p_pharmacy_id': pharmacyId},
    );
    return result == true;
  }

  // ---- Summary ----

  Future<Map<String, dynamic>> getSessionSummary(String sessionId) async {
    try {
      final response = await _client
          .from('cash_summary')
          .select()
          .eq('session_id', sessionId)
          .maybeSingle();
      if (response == null) return {};
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get cash summary: $e');
    }
  }

  Future<Map<String, dynamic>> getCashReport({
    required String pharmacyId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final sessions = await getSessions(
        pharmacyId: pharmacyId,
        fromDate: fromDate,
        toDate: toDate,
      );

      int totalOpening = 0;
      int totalSales = 0;
      int totalRefunds = 0;
      int totalWithdrawals = 0;
      int totalDeposits = 0;
      int totalClosing = 0;

      for (final session in sessions) {
        final summary = await getSessionSummary(session.id);
        totalOpening += session.openingBalance;
        totalSales += (summary['total_sales'] as int? ?? 0);
        totalRefunds += (summary['total_refunds'] as int? ?? 0);
        totalWithdrawals += (summary['total_withdrawals'] as int? ?? 0);
        totalDeposits += (summary['total_deposits'] as int? ?? 0);
        if (session.closingBalance != null) {
          totalClosing += session.closingBalance!;
        }
      }

      return {
        'total_sessions': sessions.length,
        'total_opening': totalOpening,
        'total_sales': totalSales,
        'total_refunds': totalRefunds,
        'total_withdrawals': totalWithdrawals,
        'total_deposits': totalDeposits,
        'total_closing': totalClosing,
        'net_cash':
            totalOpening +
            totalSales -
            totalRefunds -
            totalWithdrawals +
            totalDeposits,
      };
    } catch (e) {
      throw Exception('Failed to get cash report: $e');
    }
  }
}
