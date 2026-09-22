import 'dart:async';
import 'package:flutter/material.dart';
import '../models/traceable_batch.dart';
import '../models/batch_status.dart';
import '../models/batch_movement.dart';
import '../models/cold_chain_record.dart';
import '../models/verification_result.dart';
import '../models/counterfeit_report.dart';
import '../services/traceability_service.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../recall/models/recall_severity.dart';

class TraceabilityProvider extends ChangeNotifier {
  final TraceabilityService _service = TraceabilityService();
  final OfflineSyncService _offlineSync = OfflineSyncService();

  List<TraceableBatch> _batches = [];
  TraceableBatch? _selectedBatch;
  List<BatchMovement> _movements = [];
  List<ColdChainRecord> _coldChainRecords = [];
  VerificationResult? _verificationResult;
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  bool _isReceiving = false;
  bool _isSubmittingReport = false;
  CounterfeitReport? _lastReport;
  String? _error;

  // Getters
  List<TraceableBatch> get batches => _batches;
  TraceableBatch? get selectedBatch => _selectedBatch;
  List<BatchMovement> get movements => _movements;
  List<ColdChainRecord> get coldChainRecords => _coldChainRecords;
  VerificationResult? get verificationResult => _verificationResult;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get isReceiving => _isReceiving;
  bool get isSubmittingReport => _isSubmittingReport;
  CounterfeitReport? get lastReport => _lastReport;
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
      // Directive standing « privilégier le mode hors-ligne » : dernière
      // lecture réussie mise en cache pour repli si le réseau échoue
      // ensuite (même patron que STK/ORD/RES/LIV/ALR/IA).
      unawaited(
        _offlineSync.cacheTraceableBatches(
          _batches.map((b) => b.toJson()).toList(),
        ),
      );
    } catch (e) {
      final cached = await _offlineSync.getCachedTraceableBatches();
      if (cached.isNotEmpty && status == null && productId == null &&
          isRecalled == null && isCounterfeit == null) {
        _batches = cached.map((j) => TraceableBatch.fromJson(j)).toList();
      } else {
        _error = e.toString();
      }
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
    required String issuedBy,
    RecallSeverity severity = RecallSeverity.classII,
    int totalUnits = 0,
    bool isPublic = false,
    String? notes,
  }) async {
    try {
      final updated = await _service.recallBatch(
        batchId,
        reason: reason,
        issuedBy: issuedBy,
        severity: severity,
        totalUnits: totalUnits,
        isPublic: isPublic,
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

  // ==================== RÉCEPTION (RG-TRC-01) ====================

  Future<bool> receiveBatch({
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
    _isReceiving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.receiveBatch(
        batchId: batchId,
        fromLocation: fromLocation,
        toLocation: toLocation,
        fromLocationType: fromLocationType,
        toLocationType: toLocationType,
        newStatus: newStatus,
        trackingNumber: trackingNumber,
        notes: notes,
        temperature: temperature,
        isColdChainRequired: isColdChainRequired,
      );
      _updateBatch(updated);
      _isReceiving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isReceiving = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== SIGNALEMENT (RG-TRC-02) ====================

  Future<bool> reportSuspiciousProduct({
    String? batchId,
    String? serialNumber,
    String? pharmacyId,
    required String description,
    bool aspectSuspect = false,
    bool packagingSuspect = false,
    bool unexpectedEffect = false,
  }) async {
    _isSubmittingReport = true;
    _error = null;
    notifyListeners();

    try {
      _lastReport = await _service.reportSuspiciousProduct(
        batchId: batchId,
        serialNumber: serialNumber,
        pharmacyId: pharmacyId,
        description: description,
        aspectSuspect: aspectSuspect,
        packagingSuspect: packagingSuspect,
        unexpectedEffect: unexpectedEffect,
      );
      _isSubmittingReport = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmittingReport = false;
      notifyListeners();
      return false;
    }
  }

  void clearLastReport() {
    _lastReport = null;
    notifyListeners();
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
