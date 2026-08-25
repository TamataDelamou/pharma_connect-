import 'package:flutter/material.dart';
import '../models/recall.dart';
import '../models/recall_severity.dart';
import '../models/recall_status.dart';
import '../models/recall_affected_batch.dart';
import '../models/batch_recall_status.dart';
import '../services/recall_service.dart';

class RecallProvider extends ChangeNotifier {
  final RecallService _service = RecallService();

  List<Recall> _recalls = [];
  Recall? _selectedRecall;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _statistics = {};

  // Getters
  List<Recall> get recalls => _recalls;
  Recall? get selectedRecall => _selectedRecall;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get statistics => _statistics;

  List<Recall> get activeRecalls => _recalls.where((r) => r.isActive).toList();

  List<Recall> get completedRecalls =>
      _recalls.where((r) => r.isCompleted).toList();

  List<Recall> get draftRecalls =>
      _recalls.where((r) => r.status == RecallStatus.draft).toList();

  List<Recall> get classIRecalls =>
      _recalls.where((r) => r.severity == RecallSeverity.classI).toList();

  // ==================== CHARGEMENT ====================

  Future<void> loadRecalls({
    RecallStatus? status,
    RecallSeverity? severity,
    String? batchId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recalls = await _service.getRecalls(
        status: status,
        severity: severity,
        batchId: batchId,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecall(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedRecall = await _service.getRecall(id);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStatistics() async {
    try {
      _statistics = await _service.getStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== CRÉATION ====================

  Future<Recall?> createRecall({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recall = await _service.createRecall(
        title: title,
        description: description,
        severity: severity,
        issuedBy: issuedBy,
        affectedBatches: affectedBatches,
        reason: reason,
        correctiveAction: correctiveAction,
        distributionInstructions: distributionInstructions,
        isPublic: isPublic,
        notes: notes,
      );
      _recalls.add(recall);
      _isLoading = false;
      notifyListeners();
      return recall;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== ACTIONS ====================

  Future<bool> publishRecall(String id) async {
    try {
      final updated = await _service.publishRecall(id);
      _updateRecall(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeRecall(String id) async {
    try {
      final updated = await _service.completeRecall(id);
      _updateRecall(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRecall(String id, {String? reason}) async {
    try {
      final updated = await _service.cancelRecall(id, reason: reason);
      _updateRecall(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBatchStatus(
    String recallId,
    String affectedBatchId,
    BatchRecallStatus newStatus, {
    int? unitsReturned,
    int? unitsDestroyed,
  }) async {
    try {
      final updated = await _service.updateBatchStatus(
        recallId,
        affectedBatchId,
        newStatus,
        unitsReturned: unitsReturned,
        unitsDestroyed: unitsDestroyed,
      );
      _updateRecall(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== UTILITAIRES ====================

  void _updateRecall(Recall updated) {
    final index = _recalls.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _recalls[index] = updated;
    }
    if (_selectedRecall?.id == updated.id) {
      _selectedRecall = updated;
    }
    notifyListeners();
  }

  void clearSelected() {
    _selectedRecall = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
