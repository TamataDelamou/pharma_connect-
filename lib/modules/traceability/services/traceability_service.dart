import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/traceable_batch.dart';
import '../models/batch_status.dart';
import '../models/batch_movement.dart';
import '../models/cold_chain_record.dart';
import '../models/verification_result.dart';
import '../models/counterfeit_report.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../alerts/services/alert_service.dart';
import '../../alerts/models/alert_type.dart';
import '../../alerts/models/alert_severity.dart';
import '../../recall/models/recall_severity.dart';
import '../../recall/models/recall_affected_batch.dart';
import '../../recall/models/batch_recall_status.dart';
import '../../recall/services/recall_service.dart';

class TraceabilityService {
  SupabaseClient get _client => SupabaseService().client;

  static const _batchSelect =
      '*, batch_movements(*), cold_chain_records(*), certificates(*)';

  Future<List<TraceableBatch>> getBatches({
    BatchStatus? status,
    String? productId,
    bool? isRecalled,
    bool? isCounterfeit,
  }) async {
    var query = _client.from('traceable_batches').select(_batchSelect);

    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (productId != null) {
      query = query.eq('product_id', productId);
    }
    if (isRecalled != null) {
      query = query.eq('is_recalled', isRecalled);
    }
    if (isCounterfeit != null) {
      query = query.eq('is_counterfeit', isCounterfeit);
    }

    final rows = await query;
    return rows.map((row) => TraceableBatch.fromJson(row)).toList();
  }

  Future<TraceableBatch> getBatch(String id) async {
    final row = await _client
        .from('traceable_batches')
        .select(_batchSelect)
        .eq('id', id)
        .single();
    return TraceableBatch.fromJson(row);
  }

  Future<TraceableBatch?> getBatchBySerialNumber(String serialNumber) async {
    final row = await _client
        .from('traceable_batches')
        .select(_batchSelect)
        .eq('serial_number', serialNumber)
        .maybeSingle();
    return row != null ? TraceableBatch.fromJson(row) : null;
  }

  Future<TraceableBatch?> getBatchByBatchNumber(String batchNumber) async {
    final row = await _client
        .from('traceable_batches')
        .select(_batchSelect)
        .eq('batch_number', batchNumber)
        .maybeSingle();
    return row != null ? TraceableBatch.fromJson(row) : null;
  }

  Future<List<BatchMovement>> getMovements(String batchId) async {
    final rows = await _client
        .from('batch_movements')
        .select()
        .eq('batch_id', batchId)
        .order('timestamp', ascending: false);
    return rows.map((row) => BatchMovement.fromJson(row)).toList();
  }

  Future<List<ColdChainRecord>> getColdChainRecords(String batchId) async {
    final rows = await _client
        .from('cold_chain_records')
        .select()
        .eq('batch_id', batchId)
        .order('timestamp', ascending: false);
    return rows.map((row) => ColdChainRecord.fromJson(row)).toList();
  }

  // ==================== VÉRIFICATION ====================

  Future<VerificationResult> verifyProduct({
    required String serialNumber,
    required String gtin,
    String? verifiedBy,
  }) async {
    final batch = await getBatchBySerialNumber(serialNumber);
    // verified_by référence auth.users(id) : seul l'utilisateur authentifié
    // réel est enregistré, jamais un libellé libre passé par l'appelant.
    final verifierId = SupabaseService().currentUser?.id;

    late VerificationResult result;

    if (batch == null) {
      result = VerificationResult(
        batchId: 'unknown',
        serialNumber: serialNumber,
        gtin: gtin,
        isAuthentic: false,
        isCounterfeit: false,
        isRecalled: false,
        isValid: false,
        timestamp: DateTime.now(),
        verifiedBy: verifiedBy,
        message: 'Aucun produit trouvé avec ce numéro de série',
        status: VerificationStatus.invalid,
      );
    } else if (batch.gtin != gtin) {
      result = VerificationResult(
        batchId: batch.id,
        serialNumber: serialNumber,
        gtin: gtin,
        isAuthentic: false,
        isCounterfeit: true,
        isRecalled: batch.isRecalled,
        isValid: false,
        timestamp: DateTime.now(),
        verifiedBy: verifiedBy,
        productName: batch.productName,
        batchNumber: batch.batchNumber,
        manufacturingDate: batch.manufacturingDate,
        expiryDate: batch.expiryDate,
        manufacturer: batch.manufacturer,
        message:
            'GTIN ne correspond pas au numéro de série - Contrefaçon suspectée',
        status: VerificationStatus.counterfeit,
      );
    } else if (batch.isRecalled) {
      result = VerificationResult(
        batchId: batch.id,
        serialNumber: serialNumber,
        gtin: gtin,
        isAuthentic: true,
        isCounterfeit: false,
        isRecalled: true,
        isValid: true,
        timestamp: DateTime.now(),
        verifiedBy: verifiedBy,
        productName: batch.productName,
        batchNumber: batch.batchNumber,
        manufacturingDate: batch.manufacturingDate,
        expiryDate: batch.expiryDate,
        manufacturer: batch.manufacturer,
        message: '⚠️ Ce produit fait l\'objet d\'un rappel : ${batch.recallReason}',
        status: VerificationStatus.recalled,
      );
    } else {
      result = VerificationResult(
        batchId: batch.id,
        serialNumber: serialNumber,
        gtin: gtin,
        isAuthentic: true,
        isCounterfeit: false,
        isRecalled: false,
        isValid: true,
        timestamp: DateTime.now(),
        verifiedBy: verifiedBy,
        productName: batch.productName,
        batchNumber: batch.batchNumber,
        manufacturingDate: batch.manufacturingDate,
        expiryDate: batch.expiryDate,
        manufacturer: batch.manufacturer,
        message: '✅ Produit authentique',
        status: VerificationStatus.authentic,
      );
    }

    // Chaque scan est journalisé, quelle que soit l'issue — c'est la donnée
    // de pharmacovigilance (détection de contrefaçon par scans répétés sur
    // un même numéro de série), pas seulement un résultat d'écran.
    final scan = {...result.toJson(), 'verified_by': verifierId};
    await _client.from('verification_scans').insert(scan);

    // Correctif audit Module 12 (29/08/2026) : le résultat d'un scan n'était
    // jamais reporté sur le lot lui-même (is_authenticated/is_counterfeit/
    // last_verified_at restaient figés à leurs valeurs par défaut pour
    // toujours) — aucune boucle de rétroaction entre la vérification et la
    // fiche du lot, alors que traceable_batches.needsVerification/
    // isCounterfeit en dépendent directement (dashboard, liste des lots).
    // Best-effort : le scan est déjà journalisé ci-dessus, une panne réseau
    // ici ne doit pas transformer une vérification réussie en échec.
    if (batch != null) {
      try {
        await _client
            .from('traceable_batches')
            .update({
              'is_authenticated': result.isAuthentic,
              'is_counterfeit': result.isCounterfeit,
              'last_verified_at': result.timestamp.toIso8601String(),
            })
            .eq('id', batch.id);
      } catch (_) {
        // Best-effort, cf. commentaire ci-dessus.
      }
    }

    return result;
  }

  // ==================== HISTORIQUE ====================

  Future<List<VerificationResult>> getVerificationHistory(
    String serialNumber,
  ) async {
    final rows = await _client
        .from('verification_scans')
        .select()
        .eq('serial_number', serialNumber)
        .order('timestamp', ascending: false);
    return rows.map((row) => VerificationResult.fromJson(row)).toList();
  }

  // ==================== RAPPEL ====================

  Future<TraceableBatch> recallBatch(
    String batchId, {
    required String reason,
    required String issuedBy,
    RecallSeverity severity = RecallSeverity.classII,
    int totalUnits = 0,
    bool isPublic = false,
    String? notes,
  }) async {
    final current = await getBatch(batchId);

    // Correctif porteur du projet (29/08/2026, clôture Module 12) :
    // « Déclarer un rappel » ne se contentait que de poser le flag
    // is_recalled sur ce lot — le module recall (pharmacovigilance),
    // construit dès avant ce module avec un workflow bien plus riche
    // (sévérité Classe I/II/III, statut de rappel, statut par lot, action
    // corrective, diffusion publique), en était totalement déconnecté :
    // deux enregistrements de rappel non synchronisés pour le même lot.
    // Unifié ici : ce lot devient le premier (et pour l'instant seul) lot
    // affecté d'un vrai `Recall`, publié immédiatement (le pharmacien
    // déclare, il ne rédige pas un brouillon). Le flag is_recalled reste
    // écrit en parallèle ci-dessous : c'est la lecture rapide sans
    // jointure utilisée par receiveBatch (bloque une réception, RG-TRC-01)
    // et par toute l'UI de ce module ; recall_affected_batches.batch_id
    // relie ce lot au dossier de rappel complet pour qui veut le détail
    // (registre C41/D21).
    try {
      final recall = await RecallService().createRecall(
        title: 'Rappel — ${current.productName} (lot ${current.batchNumber})',
        description: reason,
        severity: severity,
        issuedBy: issuedBy,
        affectedBatches: [
          RecallAffectedBatch(
            id: '',
            recallId: '',
            batchId: current.id,
            batchNumber: current.batchNumber,
            productName: current.productName,
            productId: current.productId,
            totalUnits: totalUnits,
            status: BatchRecallStatus.pending,
          ),
        ],
        reason: reason,
        isPublic: isPublic,
      );
      await RecallService().publishRecall(recall.id);
    } catch (_) {
      // Best-effort : un échec du module recall (RLS pas encore migrée en
      // production, réseau) ne doit pas empêcher le blocage immédiat du
      // lot lui-même ci-dessous, qui reste la protection minimale de
      // RG-TRC-01 même sans le dossier de rappel complet.
    }

    final row = await _client
        .from('traceable_batches')
        .update({
          'is_recalled': true,
          'recalled_at': DateTime.now().toIso8601String(),
          'recall_reason': reason,
          'status': BatchStatus.recalled.name,
          'notes': notes,
        })
        .eq('id', batchId)
        .select(_batchSelect)
        .single();
    final updated = TraceableBatch.fromJson(row);
    // Correctif audit Module 12 : aucune écriture ne créait jamais de
    // batch_movement — voir _recordMovement ci-dessous.
    await _recordMovement(
      batchId: batchId,
      type: BatchMovementType.recall,
      fromLocation: updated.statusLabel,
      toLocation: 'Rappel',
      notes: reason,
    );
    return updated;
  }

  Future<TraceableBatch> updateBatchStatus(
    String batchId,
    BatchStatus newStatus, {
    String? notes,
    String? fromLocation,
    String? toLocation,
    String? fromLocationType,
    String? toLocationType,
  }) async {
    final row = await _client
        .from('traceable_batches')
        .update({'status': newStatus.name, 'notes': notes})
        .eq('id', batchId)
        .select(_batchSelect)
        .single();
    final updated = TraceableBatch.fromJson(row);
    await _recordMovement(
      batchId: batchId,
      type: _movementTypeForStatus(newStatus),
      fromLocation: fromLocation ?? updated.statusLabel,
      toLocation: toLocation ?? newStatus.label,
      fromLocationType: fromLocationType ?? 'pharmacy',
      toLocationType: toLocationType ?? 'pharmacy',
      notes: notes,
    );
    return updated;
  }

  // ==================== RÉCEPTION (RG-TRC-01) ====================
  //
  // Audit Module 12 (29/08/2026), arbitrage D19 : aucun écran ni aucune
  // méthode de service ne permettait d'enregistrer la réception d'un lot
  // (grossiste ← fabricant, officine ← grossiste) — la « chaîne de
  // traçabilité continue » exigée par le cahier n'existait donc que pour la
  // vérification finale (scan patient/pharmacien), jamais pour les étapes
  // amont. Enforcement PARTIEL de RG-TRC-01 : ce blocage s'applique
  // seulement à l'entrée dans la chaîne de traçabilité elle-même (on ne peut
  // pas réceptionner un lot rappelé/contrefait) — il n'est pas relié au
  // point de vente réel (Module 6 réservations / Module POS), qui reste
  // capable d'écouler un lot déjà en stock sans consulter traceable_batches.
  // Documenté au registre des écarts (item B, même précédent que B11).
  Future<TraceableBatch> receiveBatch({
    required String batchId,
    required String fromLocation,
    required String toLocation,
    required String fromLocationType,
    required String toLocationType,
    BatchStatus? newStatus,
    String? trackingNumber,
    String? notes,
    int? temperature,
    bool isColdChainRequired = false,
  }) async {
    final current = await getBatch(batchId);
    if (current.isRecalled) {
      throw StateError(
        'Ce lot fait l\'objet d\'un rappel (${current.recallReason ?? "raison non précisée"}) '
        '— réception bloquée.',
      );
    }
    if (current.isCounterfeit) {
      throw StateError(
        'Ce lot a été détecté comme contrefait — réception bloquée.',
      );
    }

    final resolvedStatus = newStatus ?? _statusForLocationType(toLocationType);
    final movementId = const Uuid().v4();
    final movement = {
      'id': movementId,
      'batch_id': batchId,
      'type': BatchMovementType.receipt.name,
      'from_location': fromLocation,
      'to_location': toLocation,
      'from_location_type': fromLocationType,
      'to_location_type': toLocationType,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': SupabaseService().currentUser?.id,
      'tracking_number': trackingNumber,
      'notes': notes,
      'temperature': temperature,
      'is_cold_chain_required': isColdChainRequired,
    };
    final statusPatch = {'status': resolvedStatus.name};

    // Directive standing « privilégier le mode hors-ligne » : rejouable sans
    // risque (idempotent côté serveur : un statut réécrit à l'identique ou
    // un mouvement horodaté une fois n'a pas d'effet de bord cumulatif),
    // contrairement aux paiements (PAY, D13) — même logique que les
    // ajustements de stock (STK).
    if (await OfflineSyncService().hasInternet()) {
      await _client.from('batch_movements').insert(movement);
      final row = await _client
          .from('traceable_batches')
          .update(statusPatch)
          .eq('id', batchId)
          .select(_batchSelect)
          .single();
      return TraceableBatch.fromJson(row);
    }

    await OfflineSyncService().queueOperation(
      table: 'batch_movements',
      recordId: movementId,
      operation: 'insert',
      data: movement,
    );
    await OfflineSyncService().queueOperation(
      table: 'traceable_batches',
      recordId: batchId,
      operation: 'update',
      data: statusPatch,
    );
    return current.copyWith(status: resolvedStatus);
  }

  // ==================== SIGNALEMENT (RG-TRC-02) ====================

  Future<CounterfeitReport> reportSuspiciousProduct({
    String? batchId,
    String? serialNumber,
    String? pharmacyId,
    required String description,
    bool aspectSuspect = false,
    bool packagingSuspect = false,
    bool unexpectedEffect = false,
  }) async {
    final reporterId = SupabaseService().currentUser?.id;
    if (reporterId == null) {
      throw StateError('Utilisateur non authentifié.');
    }
    // Un signalement déclenche une alerte immédiate vers l'officine et
    // l'admin GSG (RG-TRC-02) — contrairement à receiveBatch ci-dessus, cet
    // enchaînement signalement+alerte n'est pas rejouable proprement par la
    // file d'attente générique (deux tables, deux écritures indépendantes) :
    // le différer hors-ligne créerait un signalement silencieusement "orphelin"
    // sans alerte tant que la synchronisation générique n'a pas connaissance
    // du besoin de créer l'alerte associée. Décision documentée au registre
    // des écarts plutôt que traitée en silence (même précédent que PAY/D13).
    if (!await OfflineSyncService().hasInternet()) {
      throw StateError(
        'Le signalement d\'un produit suspect nécessite une connexion : '
        'il doit alerter l\'officine et l\'administrateur GSG immédiatement.',
      );
    }

    final id = const Uuid().v4();
    await _client.from('counterfeit_reports').insert({
      'id': id,
      'reporter_id': reporterId,
      'batch_id': batchId,
      'serial_number': serialNumber,
      'pharmacy_id': pharmacyId,
      'description': description,
      'aspect_suspect': aspectSuspect,
      'packaging_suspect': packagingSuspect,
      'unexpected_effect': unexpectedEffect,
    });

    final alert = await AlertService().createAlert(
      type: AlertType.counterfeit,
      severity: AlertSeverity.critical,
      title: 'Produit suspect signalé',
      message: description,
      referenceId: id,
      referenceType: 'counterfeit_report',
      pharmacyId: pharmacyId,
      actionRoute: '/traceability/report',
    );

    final row = await _client
        .from('counterfeit_reports')
        .update({'alert_id': alert.id})
        .eq('id', id)
        .select()
        .single();
    return CounterfeitReport.fromJson(row);
  }

  // ==================== UTILITAIRES INTERNES ====================

  /// Best-effort : le rappel/changement de statut/réception a déjà réussi
  /// côté métier au moment de l'appel — un mouvement de traçabilité qui
  /// échoue à s'enregistrer ne doit pas transformer une action réussie en
  /// échec (même logique que _persistProfile, auth_provider.dart).
  Future<void> _recordMovement({
    required String batchId,
    required BatchMovementType type,
    required String fromLocation,
    required String toLocation,
    String fromLocationType = 'pharmacy',
    String toLocationType = 'pharmacy',
    String? notes,
  }) async {
    try {
      await _client.from('batch_movements').insert({
        'id': const Uuid().v4(),
        'batch_id': batchId,
        'type': type.name,
        'from_location': fromLocation,
        'to_location': toLocation,
        'from_location_type': fromLocationType,
        'to_location_type': toLocationType,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': SupabaseService().currentUser?.id,
        'notes': notes,
      });
    } catch (_) {
      // Best-effort, cf. docstring ci-dessus.
    }
  }

  BatchMovementType _movementTypeForStatus(BatchStatus status) {
    switch (status) {
      case BatchStatus.sold:
        return BatchMovementType.sale;
      case BatchStatus.dispensed:
        return BatchMovementType.dispensation;
      case BatchStatus.returned:
        return BatchMovementType.customerReturn;
      case BatchStatus.recalled:
        return BatchMovementType.recall;
      case BatchStatus.destroyed:
        return BatchMovementType.destruction;
      case BatchStatus.inTransit:
      case BatchStatus.atDistributor:
      case BatchStatus.atPharmacy:
      case BatchStatus.manufactured:
        return BatchMovementType.transfer;
    }
  }

  BatchStatus _statusForLocationType(String locationType) {
    switch (locationType) {
      case 'distributor':
        return BatchStatus.atDistributor;
      case 'pharmacy':
        return BatchStatus.atPharmacy;
      case 'patient':
        return BatchStatus.dispensed;
      case 'manufacturer':
        return BatchStatus.manufactured;
      default:
        return BatchStatus.inTransit;
    }
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getStatistics() async {
    final batches = await getBatches();

    return {
      'totalBatches': batches.length,
      'activeBatches': batches.where((b) => b.isActive).length,
      'recalledBatches': batches.where((b) => b.isRecalled).length,
      'counterfeitDetected': batches.where((b) => b.isCounterfeit).length,
      'authenticated': batches.where((b) => b.isAuthenticated).length,
      'byStatus': {
        for (final status in BatchStatus.values)
          status.label: batches.where((b) => b.status == status).length,
      },
    };
  }
}
