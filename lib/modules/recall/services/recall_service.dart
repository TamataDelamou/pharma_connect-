import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/recall.dart';
import '../models/recall_severity.dart';
import '../models/recall_status.dart';
import '../models/recall_affected_batch.dart';
import '../models/batch_recall_status.dart';
import '../../../core/services/supabase_service.dart';

class RecallService {
  SupabaseClient get _client => SupabaseService().client;

  static const _recallSelect = '*, recall_affected_batches(*)';

  Future<List<Recall>> getRecalls({
    RecallStatus? status,
    RecallSeverity? severity,
    String? batchId,
  }) async {
    var query = _client.from('recalls').select(_recallSelect);

    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (severity != null) {
      query = query.eq('severity', severity.name);
    }
    if (batchId != null) {
      query = query.eq('recall_affected_batches.batch_id', batchId);
    }

    final rows = await query.order('issued_at', ascending: false);
    return rows.map((row) => Recall.fromJson(row)).toList();
  }

  Future<Recall> getRecall(String id) async {
    final row = await _client
        .from('recalls')
        .select(_recallSelect)
        .eq('id', id)
        .single();
    return Recall.fromJson(row);
  }

  Future<String> _nextReferenceNumber() async {
    // Pas de séquence Postgres dédiée : calculé côté client à partir du
    // nombre de rappels déjà émis cette année. Course possible entre deux
    // créations concurrentes (même limite que l'ancien compteur en mémoire).
    final year = DateTime.now().year;
    final existing = await _client
        .from('recalls')
        .select('id')
        .ilike('reference_number', 'RCL-$year-%');
    return 'RCL-$year-${(existing.length + 1).toString().padLeft(3, '0')}';
  }

  Future<Recall> createRecall({
    required String title,
    required String description,
    required RecallSeverity severity,
    required String issuedBy,
    required List<RecallAffectedBatch> affectedBatches,
    String? reason,
    String? correctiveAction,
    String? distributionInstructions,
    bool isPublic = true,
    String? notes,
  }) async {
    final referenceNumber = await _nextReferenceNumber();

    final recall = Recall(
      id: const Uuid().v4(),
      referenceNumber: referenceNumber,
      title: title,
      description: description,
      severity: severity,
      status: RecallStatus.draft,
      affectedBatches: const [],
      issuedAt: DateTime.now(),
      issuedBy: issuedBy,
      reason: reason,
      correctiveAction: correctiveAction,
      distributionInstructions: distributionInstructions,
      isPublic: isPublic,
      totalAffectedUnits: affectedBatches.fold<int>(
        0,
        (sum, b) => sum + b.totalUnits,
      ),
      unitsReturned: 0,
      unitsDestroyed: 0,
      unitsUnrecovered: 0,
      notes: notes,
    );

    final row = await _client
        .from('recalls')
        .insert(recall.toJson())
        .select()
        .single();
    final created = Recall.fromJson(row);

    if (affectedBatches.isNotEmpty) {
      final batchRows = affectedBatches
          .map(
            (b) => b
                .copyWith(id: const Uuid().v4(), recallId: created.id)
                .toJson(),
          )
          .toList();
      await _client.from('recall_affected_batches').insert(batchRows);
    }

    return getRecall(created.id);
  }

  Future<Recall> publishRecall(String id) async {
    final row = await _client
        .from('recalls')
        .update({'status': RecallStatus.inProgress.name})
        .eq('id', id)
        .select(_recallSelect)
        .single();
    final updated = Recall.fromJson(row);

    // Créer des alertes pour les pharmacies concernées — voir
    // AlertService.createAlert pour le patron équivalent.
    await _notifyStakeholders(updated);

    return updated;
  }

  Future<Recall> completeRecall(String id) async {
    final row = await _client
        .from('recalls')
        .update({
          'status': RecallStatus.completed.name,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select(_recallSelect)
        .single();
    return Recall.fromJson(row);
  }

  Future<Recall> cancelRecall(String id, {String? reason}) async {
    final row = await _client
        .from('recalls')
        .update({'status': RecallStatus.cancelled.name, 'notes': reason})
        .eq('id', id)
        .select(_recallSelect)
        .single();
    return Recall.fromJson(row);
  }

  Future<Recall> updateBatchStatus(
    String recallId,
    String affectedBatchId,
    BatchRecallStatus newStatus, {
    int? unitsReturned,
    int? unitsDestroyed,
  }) async {
    final batchUpdate = <String, dynamic>{'status': newStatus.name};
    if (unitsReturned != null) batchUpdate['units_returned'] = unitsReturned;
    if (unitsDestroyed != null) {
      batchUpdate['units_destroyed'] = unitsDestroyed;
    }

    await _client
        .from('recall_affected_batches')
        .update(batchUpdate)
        .eq('id', affectedBatchId);

    // Recalculer les totaux du rappel à partir de tous ses lots.
    final batchRows = await _client
        .from('recall_affected_batches')
        .select()
        .eq('recall_id', recallId);
    final batches = batchRows
        .map((row) => RecallAffectedBatch.fromJson(row))
        .toList();

    final totalAffected = batches.fold<int>(0, (sum, b) => sum + b.totalUnits);
    final totalReturned = batches.fold<int>(
      0,
      (sum, b) => sum + b.unitsReturned,
    );
    final totalDestroyed = batches.fold<int>(
      0,
      (sum, b) => sum + b.unitsDestroyed,
    );

    final row = await _client
        .from('recalls')
        .update({
          'total_affected_units': totalAffected,
          'units_returned': totalReturned,
          'units_destroyed': totalDestroyed,
          'units_unrecovered': totalAffected - totalReturned - totalDestroyed,
        })
        .eq('id', recallId)
        .select(_recallSelect)
        .single();

    return Recall.fromJson(row);
  }

  // ==================== NOTIFICATIONS ====================

  Future<void> _notifyStakeholders(Recall recall) async {
    // Dans la réalité, on utiliserait AlertService.createAlert pour chaque
    // pharmacie détenant un lot affecté.
    for (final _ in recall.affectedBatches) {
      // alertService.createAlert(...)
    }
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getStatistics() async {
    final recalls = await getRecalls();

    return {
      'totalRecalls': recalls.length,
      'activeRecalls': recalls.where((r) => r.isActive).length,
      'completedRecalls': recalls.where((r) => r.isCompleted).length,
      'bySeverity': {
        'classI': recalls
            .where((r) => r.severity == RecallSeverity.classI)
            .length,
        'classII': recalls
            .where((r) => r.severity == RecallSeverity.classII)
            .length,
        'classIII': recalls
            .where((r) => r.severity == RecallSeverity.classIII)
            .length,
      },
      'averageCompletionRate': recalls.isEmpty
          ? 0
          : recalls.fold(0.0, (sum, r) => sum + r.completionRate) /
                recalls.length,
      'totalUnitsReturned': recalls.fold(
        0,
        (sum, r) => sum + (r.unitsReturned ?? 0),
      ),
      'totalUnitsDestroyed': recalls.fold(
        0,
        (sum, r) => sum + (r.unitsDestroyed ?? 0),
      ),
    };
  }
}
