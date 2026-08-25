import 'dart:math';
import '../models/traceable_batch.dart';
import '../models/batch_status.dart';
import '../models/batch_movement.dart';
import '../models/cold_chain_record.dart';
import '../models/certificate.dart';
import '../models/verification_result.dart';

class TraceabilityService {
  static final List<TraceableBatch> _batches = [];
  static final Random _random = Random();
  static final Map<String, List<String>> _verificationHistory = {};

  // ==================== DONNÉES MOCKÉES ====================

  static final List<TraceableBatch> _mockBatches = [
    _createMockBatch(
      id: 'tb_001',
      productName: 'Doliprane 1000mg',
      batchNumber: 'DOL-2024-001',
      serialNumber: 'SN-DOL-001-2024',
      gtin: '0032456789012',
      status: BatchStatus.atPharmacy,
      manufacturer: 'Sanofi',
    ),
    _createMockBatch(
      id: 'tb_002',
      productName: 'Amoxicilline 500mg',
      batchNumber: 'AMX-2024-002',
      serialNumber: 'SN-AMX-002-2024',
      gtin: '0032456789013',
      status: BatchStatus.atDistributor,
      manufacturer: 'Biogaran',
    ),
    _createMockBatch(
      id: 'tb_003',
      productName: 'Ventoline 100µg',
      batchNumber: 'VEN-2024-003',
      serialNumber: 'SN-VEN-003-2024',
      gtin: '0032456789014',
      status: BatchStatus.inTransit,
      manufacturer: 'GSK',
    ),
    _createMockBatch(
      id: 'tb_004',
      productName: 'Spasfon 80mg',
      batchNumber: 'SPA-2024-004',
      serialNumber: 'SN-SPA-004-2024',
      gtin: '0032456789015',
      status: BatchStatus.sold,
      manufacturer: 'Teva',
    ),
    _createMockBatch(
      id: 'tb_005',
      productName: 'Crestor 10mg',
      batchNumber: 'CRE-2024-005',
      serialNumber: 'SN-CRE-005-2024',
      gtin: '0032456789016',
      status: BatchStatus.recalled,
      manufacturer: 'AstraZeneca',
      isRecalled: true,
      recallReason: 'Défaut de fabrication',
    ),
  ];

  static TraceableBatch _createMockBatch({
    required String id,
    required String productName,
    required String batchNumber,
    required String serialNumber,
    required String gtin,
    required BatchStatus status,
    required String manufacturer,
    bool isRecalled = false,
    String? recallReason,
  }) {
    final now = DateTime.now();
    final movements = [
      BatchMovement(
        id: 'mov_${_random.nextInt(1000)}',
        batchId: id,
        type: BatchMovementType.shipment,
        fromLocation: 'Usine Sanofi',
        toLocation: 'Entrepôt GSG',
        fromLocationType: 'manufacturer',
        toLocationType: 'distributor',
        timestamp: now.subtract(const Duration(days: 15)),
        trackingNumber: 'TRK${_random.nextInt(1000000)}',
      ),
      BatchMovement(
        id: 'mov_${_random.nextInt(1000)}',
        batchId: id,
        type: BatchMovementType.receipt,
        fromLocation: 'Entrepôt GSG',
        toLocation: 'Pharmacie Centrale',
        fromLocationType: 'distributor',
        toLocationType: 'pharmacy',
        timestamp: now.subtract(const Duration(days: 5)),
        temperature: 22,
        isColdChainRequired: false,
      ),
    ];

    final coldChainRecords = [
      ColdChainRecord(
        id: 'cc_${_random.nextInt(1000)}',
        batchId: id,
        timestamp: now.subtract(const Duration(days: 10)),
        temperature: 21.5,
        minTemperature: 15,
        maxTemperature: 25,
        location: 'En transit',
        deviceId: 'TEMP-001',
      ),
      ColdChainRecord(
        id: 'cc_${_random.nextInt(1000)}',
        batchId: id,
        timestamp: now.subtract(const Duration(days: 5)),
        temperature: 22.3,
        minTemperature: 15,
        maxTemperature: 25,
        location: 'Pharmacie Centrale',
        deviceId: 'TEMP-001',
      ),
    ];

    final certificates = [
      Certificate(
        id: 'cert_${_random.nextInt(1000)}',
        batchId: id,
        type: 'coa',
        title: 'Certificat d\'analyse',
        issuedAt: now.subtract(const Duration(days: 30)),
        issuedBy: manufacturer,
        isValid: true,
      ),
    ];

    return TraceableBatch(
      id: id,
      productId: 'prod_${_random.nextInt(100)}',
      productName: productName,
      batchNumber: batchNumber,
      serialNumber: serialNumber,
      gtin: gtin,
      manufacturingDate: now.subtract(const Duration(days: 60)),
      expiryDate: now.add(const Duration(days: 365)),
      status: status,
      manufacturer: manufacturer,
      manufacturerId: 'man_${_random.nextInt(10)}',
      distributor: 'GSG Distribution',
      distributorId: 'dist_001',
      movements: movements,
      coldChainRecords: coldChainRecords,
      certificates: certificates,
      isAuthenticated: status != BatchStatus.recalled,
      isCounterfeit: false,
      lastVerifiedAt: status == BatchStatus.sold ? now : null,
      isRecalled: isRecalled,
      recalledAt: isRecalled ? now : null,
      recallReason: recallReason,
    );
  }

  static void _initMockData() {
    if (_batches.isEmpty) {
      _batches.addAll(_mockBatches);
    }
  }

  // ==================== MÉTHODES ====================

  Future<List<TraceableBatch>> getBatches({
    BatchStatus? status,
    String? productId,
    bool? isRecalled,
    bool? isCounterfeit,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var list = _batches;

    if (status != null) {
      list = list.where((b) => b.status == status).toList();
    }

    if (productId != null) {
      list = list.where((b) => b.productId == productId).toList();
    }

    if (isRecalled != null) {
      list = list.where((b) => b.isRecalled == isRecalled).toList();
    }

    if (isCounterfeit != null) {
      list = list.where((b) => b.isCounterfeit == isCounterfeit).toList();
    }

    return list;
  }

  Future<TraceableBatch> getBatch(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _batches.firstWhere((b) => b.id == id);
  }

  Future<TraceableBatch?> getBatchBySerialNumber(String serialNumber) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    try {
      return _batches.firstWhere((b) => b.serialNumber == serialNumber);
    } catch (_) {
      return null;
    }
  }

  Future<TraceableBatch?> getBatchByBatchNumber(String batchNumber) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    try {
      return _batches.firstWhere((b) => b.batchNumber == batchNumber);
    } catch (_) {
      return null;
    }
  }

  Future<List<BatchMovement>> getMovements(String batchId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    final batch = await getBatch(batchId);
    return batch.movements;
  }

  Future<List<ColdChainRecord>> getColdChainRecords(String batchId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    final batch = await getBatch(batchId);
    return batch.coldChainRecords;
  }

  // ==================== VÉRIFICATION ====================

  Future<VerificationResult> verifyProduct({
    required String serialNumber,
    required String gtin,
    String? verifiedBy,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    // Vérifier si le produit existe
    final batch = await getBatchBySerialNumber(serialNumber);

    if (batch == null) {
      // Enregistrer la tentative de vérification pour détection de contrefaçon
      _recordVerification(serialNumber, false);
      return VerificationResult(
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
    }

    // Vérifier le GTIN
    if (batch.gtin != gtin) {
      return VerificationResult(
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
    }

    // Vérifier si le lot est rappelé
    if (batch.isRecalled) {
      return VerificationResult(
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
        message:
            '⚠️ Ce produit fait l\'objet d\'un rappel : ${batch.recallReason}',
        status: VerificationStatus.recalled,
      );
    }

    // Produit authentique
    _recordVerification(serialNumber, true);
    return VerificationResult(
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

  void _recordVerification(String serialNumber, bool isAuthentic) {
    if (!_verificationHistory.containsKey(serialNumber)) {
      _verificationHistory[serialNumber] = [];
    }
    _verificationHistory[serialNumber]!.add(
      '${DateTime.now().toIso8601String()}:${isAuthentic ? 'AUTH' : 'SUSPECT'}',
    );

    // Détection de contrefaçon : plus de 2 vérifications différentes sur le même numéro
    if (_verificationHistory[serialNumber]!.length > 2) {
      // Créer une alerte de contrefaçon
      // alertService.createAlert(...)
    }
  }

  // ==================== HISTORIQUE ====================

  Future<List<VerificationResult>> getVerificationHistory(
    String serialNumber,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final history = <VerificationResult>[];
    // Simuler un historique
    history.add(
      VerificationResult(
        batchId: 'tb_001',
        serialNumber: serialNumber,
        gtin: '0032456789012',
        isAuthentic: true,
        isCounterfeit: false,
        isRecalled: false,
        isValid: true,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        verifiedBy: 'Pharmacien Martin',
        productName: 'Doliprane 1000mg',
        batchNumber: 'DOL-2024-001',
        status: VerificationStatus.authentic,
      ),
    );
    return history;
  }

  // ==================== RAPPEL ====================

  Future<TraceableBatch> recallBatch(
    String batchId, {
    required String reason,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _batches.indexWhere((b) => b.id == batchId);
    if (index == -1) throw Exception('Batch not found');

    final updated = _batches[index].copyWith(
      isRecalled: true,
      recalledAt: DateTime.now(),
      recallReason: reason,
      status: BatchStatus.recalled,
      notes: notes,
    );
    _batches[index] = updated;
    return updated;
  }

  Future<TraceableBatch> updateBatchStatus(
    String batchId,
    BatchStatus newStatus, {
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _batches.indexWhere((b) => b.id == batchId);
    if (index == -1) throw Exception('Batch not found');

    final updated = _batches[index].copyWith(status: newStatus, notes: notes);
    _batches[index] = updated;
    return updated;
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getStatistics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    return {
      'totalBatches': _batches.length,
      'activeBatches': _batches.where((b) => b.isActive).length,
      'recalledBatches': _batches.where((b) => b.isRecalled).length,
      'counterfeitDetected': _batches.where((b) => b.isCounterfeit).length,
      'authenticated': _batches.where((b) => b.isAuthenticated).length,
      'byStatus': {
        for (final status in BatchStatus.values)
          status.label: _batches.where((b) => b.status == status).length,
      },
    };
  }
}
