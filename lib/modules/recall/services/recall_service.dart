import 'dart:math';
import '../models/recall.dart';
import '../models/recall_severity.dart';
import '../models/recall_status.dart';
import '../models/recall_affected_batch.dart';
import '../models/batch_recall_status.dart';

class RecallService {
  static final List<Recall> _recalls = [];
  static final Random _random = Random();
  static int _counter = 0;

  // ==================== DONNÉES MOCKÉES ====================

  static final List<Recall> _mockRecalls = [
    _createMockRecall(
      id: 'rec_001',
      referenceNumber: 'RCL-2024-001',
      title: 'Rappel Doliprane 1000mg - Défaut de fabrication',
      description:
          'Rappel du lot DOL-2024-001 pour défaut de fabrication détecté lors des contrôles qualité.',
      severity: RecallSeverity.classI,
      status: RecallStatus.inProgress,
      issuedBy: 'DNPM',
      reason: 'Défaut de fabrication - risque de sous-dosage',
      correctiveAction: 'Retour du lot et remplacement par un lot conforme',
      batches: [
        _createMockAffectedBatch(
          batchId: 'tb_001',
          batchNumber: 'DOL-2024-001',
          productName: 'Doliprane 1000mg',
          totalUnits: 1000,
          status: BatchRecallStatus.inProgress,
        ),
      ],
    ),
    _createMockRecall(
      id: 'rec_002',
      referenceNumber: 'RCL-2024-002',
      title: 'Rappel Amoxicilline 500mg - Étiquetage incorrect',
      description:
          'Rappel du lot AMX-2024-002 suite à une erreur d\'étiquetage sur la date de péremption.',
      severity: RecallSeverity.classII,
      status: RecallStatus.completed,
      issuedBy: 'Biogaran',
      reason: 'Erreur d\'étiquetage',
      correctiveAction: 'Correction des étiquettes',
      batches: [
        _createMockAffectedBatch(
          batchId: 'tb_002',
          batchNumber: 'AMX-2024-002',
          productName: 'Amoxicilline 500mg',
          totalUnits: 500,
          unitsReturned: 480,
          unitsDestroyed: 20,
          status: BatchRecallStatus.completed,
        ),
      ],
    ),
  ];

  static Recall _createMockRecall({
    required String id,
    required String referenceNumber,
    required String title,
    required String description,
    required RecallSeverity severity,
    required RecallStatus status,
    required String issuedBy,
    String? reason,
    String? correctiveAction,
    required List<RecallAffectedBatch> batches,
  }) {
    final now = DateTime.now();
    return Recall(
      id: id,
      referenceNumber: referenceNumber,
      title: title,
      description: description,
      severity: severity,
      status: status,
      affectedBatches: batches,
      issuedAt: now.subtract(const Duration(days: 5)),
      updatedAt: status == RecallStatus.inProgress ? now : null,
      completedAt: status == RecallStatus.completed ? now : null,
      issuedBy: issuedBy,
      reason: reason,
      correctiveAction: correctiveAction,
      isPublic: true,
      totalAffectedUnits: batches.fold<int>(0, (sum, b) => sum + b.totalUnits),
      unitsReturned: batches.fold<int>(0, (sum, b) => sum + b.unitsReturned),
      unitsDestroyed: batches.fold<int>(0, (sum, b) => sum + b.unitsDestroyed),
      unitsUnrecovered: 0,
    );
  }

  static RecallAffectedBatch _createMockAffectedBatch({
    required String batchId,
    required String batchNumber,
    required String productName,
    required int totalUnits,
    required BatchRecallStatus status,
    int unitsReturned = 0,
    int unitsDestroyed = 0,
  }) {
    return RecallAffectedBatch(
      id: 'rab_${_random.nextInt(1000)}',
      recallId: '',
      batchId: batchId,
      batchNumber: batchNumber,
      productName: productName,
      productId: 'prod_${_random.nextInt(100)}',
      totalUnits: totalUnits,
      unitsRecalled: totalUnits,
      unitsReturned: unitsReturned,
      unitsDestroyed: unitsDestroyed,
      status: status,
    );
  }

  static void _initMockData() {
    if (_recalls.isEmpty) {
      _recalls.addAll(_mockRecalls);
      _counter = _recalls.length;
    }
  }

  // ==================== MÉTHODES ====================

  Future<List<Recall>> getRecalls({
    RecallStatus? status,
    RecallSeverity? severity,
    String? batchId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var list = _recalls;

    if (status != null) {
      list = list.where((r) => r.status == status).toList();
    }

    if (severity != null) {
      list = list.where((r) => r.severity == severity).toList();
    }

    if (batchId != null) {
      list = list
          .where((r) => r.affectedBatches.any((b) => b.batchId == batchId))
          .toList();
    }

    list.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return list;
  }

  Future<Recall> getRecall(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _recalls.firstWhere((r) => r.id == id);
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
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    _counter++;
    final id = 'rec_${DateTime.now().millisecondsSinceEpoch}';
    final referenceNumber =
        'RCL-${DateTime.now().year}-${_counter.toString().padLeft(3, '0')}';

    final recall = Recall(
      id: id,
      referenceNumber: referenceNumber,
      title: title,
      description: description,
      severity: severity,
      status: RecallStatus.draft,
      affectedBatches: affectedBatches,
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

    _recalls.add(recall);
    return recall;
  }

  Future<Recall> updateRecall(String id, Recall updatedRecall) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _recalls.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Recall not found');

    _recalls[index] = updatedRecall.copyWith(updatedAt: DateTime.now());
    return _recalls[index];
  }

  Future<Recall> publishRecall(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _recalls.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Recall not found');

    final updated = _recalls[index].copyWith(
      status: RecallStatus.inProgress,
      updatedAt: DateTime.now(),
    );
    _recalls[index] = updated;

    // Créer des alertes pour les pharmacies concernées
    await _notifyStakeholders(updated);

    return updated;
  }

  Future<Recall> completeRecall(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _recalls.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Recall not found');

    final updated = _recalls[index].copyWith(
      status: RecallStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _recalls[index] = updated;
    return updated;
  }

  Future<Recall> cancelRecall(String id, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _recalls.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Recall not found');

    final updated = _recalls[index].copyWith(
      status: RecallStatus.cancelled,
      updatedAt: DateTime.now(),
      notes: reason,
    );
    _recalls[index] = updated;
    return updated;
  }

  Future<Recall> updateBatchStatus(
    String recallId,
    String affectedBatchId,
    BatchRecallStatus newStatus, {
    int? unitsReturned,
    int? unitsDestroyed,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final index = _recalls.indexWhere((r) => r.id == recallId);
    if (index == -1) throw Exception('Recall not found');

    final recall = _recalls[index];
    final batchIndex = recall.affectedBatches.indexWhere(
      (b) => b.id == affectedBatchId,
    );
    if (batchIndex == -1) throw Exception('Affected batch not found');

    final updatedBatches = List<RecallAffectedBatch>.from(
      recall.affectedBatches,
    );
    updatedBatches[batchIndex] = updatedBatches[batchIndex].copyWith(
      status: newStatus,
      unitsReturned: unitsReturned ?? updatedBatches[batchIndex].unitsReturned,
      unitsDestroyed:
          unitsDestroyed ?? updatedBatches[batchIndex].unitsDestroyed,
    );

    // Recalculer les totaux
    final totalAffected = updatedBatches.fold(
      0,
      (sum, b) => sum + b.totalUnits,
    );
    final totalReturned = updatedBatches.fold(
      0,
      (sum, b) => sum + b.unitsReturned,
    );
    final totalDestroyed = updatedBatches.fold(
      0,
      (sum, b) => sum + b.unitsDestroyed,
    );

    final updated = recall.copyWith(
      affectedBatches: updatedBatches,
      totalAffectedUnits: totalAffected,
      unitsReturned: totalReturned,
      unitsDestroyed: totalDestroyed,
      unitsUnrecovered: totalAffected - totalReturned - totalDestroyed,
      updatedAt: DateTime.now(),
    );
    _recalls[index] = updated;
    return updated;
  }

  // ==================== NOTIFICATIONS ====================

  Future<void> _notifyStakeholders(Recall recall) async {
    // Simuler l'envoi de notifications
    // Dans la réalité, on utiliserait le module alerts
    await Future.delayed(const Duration(milliseconds: 200));

    // Pour chaque lot affecté, créer une alerte
    for (final _ in recall.affectedBatches) {
      // alertService.createAlert(...)
    }
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getStatistics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    return {
      'totalRecalls': _recalls.length,
      'activeRecalls': _recalls.where((r) => r.isActive).length,
      'completedRecalls': _recalls.where((r) => r.isCompleted).length,
      'bySeverity': {
        'classI': _recalls
            .where((r) => r.severity == RecallSeverity.classI)
            .length,
        'classII': _recalls
            .where((r) => r.severity == RecallSeverity.classII)
            .length,
        'classIII': _recalls
            .where((r) => r.severity == RecallSeverity.classIII)
            .length,
      },
      'averageCompletionRate': _recalls.isEmpty
          ? 0
          : _recalls.fold(0.0, (sum, r) => sum + r.completionRate) /
                _recalls.length,
      'totalUnitsReturned': _recalls.fold(
        0,
        (sum, r) => sum + (r.unitsReturned ?? 0),
      ),
      'totalUnitsDestroyed': _recalls.fold(
        0,
        (sum, r) => sum + (r.unitsDestroyed ?? 0),
      ),
    };
  }
}
