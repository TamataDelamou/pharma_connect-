import 'package:flutter/material.dart';
import '../models/traceable_batch.dart';
import '../models/batch_status.dart';
import '../models/batch_movement.dart';
import '../models/cold_chain_record.dart';
import '../models/verification_result.dart';
import '../services/traceability_service.dart';

class TraceabilityProvider extends ChangeNotifier {
  final TraceabilityService _service = TraceabilityService();

  List<TraceableBatch> _batches = [];
  TraceableBatch? _selectedBatch;
  List<BatchMovement> _movements = [];
  List<ColdChainRecord> _coldChainRecords = [];
  VerificationResult? _verificationResult;
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TraceableBatch> get batches => _batches;
  TraceableBatch? get selectedBatch => _selectedBatch;
  List<BatchMovement> get movements => _movements;
  List<ColdChainRecord> get coldChainRecords => _coldChainRecords;
  VerificationResult? get verificationResult => _verificationResult;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<TraceableBatch> get activeBatches =>
      _batches.where((b) => b.isActive).toList();

  List<TraceableBatch> get recalledBatches =>
      _batches.where((b) => b.isRecalled).toList();

  List<TraceableBatch> get counterfeitBatches =>
      _batches.where((b) => b.isCounterfeit).toList();

  // ==================== CHARGEMENT ====================

  Future<void> loadBatches({
    BatchStatus? status,
    String? productId,
    bool? isRecalled,
    bool? isCounterfeit,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _batches = await _service.getBatches(
        status: status,
        productId: productId,
        isRecalled: isRecalled,
        isCounterfeit: isCounterfeit,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBatch(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedBatch = await _service.getBatch(id);
      if (_selectedBatch != null) {
        _movements = await _service.getMovements(id);
        _coldChainRecords = await _service.getColdChainRecords(id);
      }
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

  // ==================== VÉRIFICATION ====================

  Future<void> verifyProduct({
    required String serialNumber,
    required String gtin,
    String? verifiedBy,
  }) async {
    _isLoading = true;
    _error = null;
    _verificationResult = null;
    notifyListeners();

    try {
      _verificationResult = await _service.verifyProduct(
        serialNumber: serialNumber,
        gtin: gtin,
        verifiedBy: verifiedBy,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearVerificationResult() {
    _verificationResult = null;
    notifyListeners();
  }

  // ==================== ACTIONS ====================

  Future<bool> recallBatch(
    String batchId, {
    required String reason,
    String? notes,
  }) async {
    try {
      final updated = await _service.recallBatch(
        batchId,
        reason: reason,
        notes: notes,
      );
      _updateBatch(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBatchStatus(
    String batchId,
    BatchStatus newStatus, {
    String? notes,
  }) async {
    try {
      final updated = await _service.updateBatchStatus(
        batchId,
        newStatus,
        notes: notes,
      );
      _updateBatch(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== UTILITAIRES ====================

  void _updateBatch(TraceableBatch updated) {
    final index = _batches.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _batches[index] = updated;
    }
    if (_selectedBatch?.id == updated.id) {
      _selectedBatch = updated;
    }
    notifyListeners();
  }

  void clearSelected() {
    _selectedBatch = null;
    _movements = [];
    _coldChainRecords = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
