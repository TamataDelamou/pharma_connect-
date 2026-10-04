import 'batch_status.dart';
import 'batch_movement.dart';
import 'cold_chain_record.dart';
import 'certificate.dart';
import '../../../core/theme/palette.dart';

class TraceableBatch {
  final String id;
  final String productId;
  final String productName;
  final String batchNumber;
  final String serialNumber;
  final String gtin;
  final DateTime manufacturingDate;
  final DateTime expiryDate;
  final BatchStatus status;
  final String manufacturer;
  final String manufacturerId;
  final String distributor;
  final String distributorId;
  final List<BatchMovement> movements;
  final List<ColdChainRecord> coldChainRecords;
  final List<Certificate> certificates;
  final bool isAuthenticated;
  final bool isCounterfeit;
  final DateTime? lastVerifiedAt;
  final bool isRecalled;
  final DateTime? recalledAt;
  final String? recallReason;
  final String? notes;

  TraceableBatch({
    required this.id,
    required this.productId,
    required this.productName,
    required this.batchNumber,
    required this.serialNumber,
    required this.gtin,
    required this.manufacturingDate,
    required this.expiryDate,
    required this.status,
    required this.manufacturer,
    required this.manufacturerId,
    required this.distributor,
    required this.distributorId,
    this.movements = const [],
    this.coldChainRecords = const [],
    this.certificates = const [],
    this.isAuthenticated = false,
    this.isCounterfeit = false,
    this.lastVerifiedAt,
    this.isRecalled = false,
    this.recalledAt,
    this.recallReason,
    this.notes,
  });

  factory TraceableBatch.fromJson(Map<String, dynamic> json) => TraceableBatch(
    id: json['id'] as String,
    productId: json['product_id'] as String? ?? '',
    productName: json['product_name'] as String,
    batchNumber: json['batch_number'] as String,
    serialNumber: json['serial_number'] as String,
    gtin: json['gtin'] as String,
    manufacturingDate: DateTime.parse(json['manufacturing_date'] as String),
    expiryDate: DateTime.parse(json['expiry_date'] as String),
    status: BatchStatus.values.byName(json['status'] as String),
    manufacturer: json['manufacturer'] as String,
    manufacturerId: json['manufacturer_id'] as String? ?? '',
    distributor: json['distributor'] as String? ?? '',
    distributorId: json['distributor_id'] as String? ?? '',
    movements: (json['batch_movements'] as List<dynamic>? ?? [])
        .map((m) => BatchMovement.fromJson(m as Map<String, dynamic>))
        .toList(),
    coldChainRecords: (json['cold_chain_records'] as List<dynamic>? ?? [])
        .map((c) => ColdChainRecord.fromJson(c as Map<String, dynamic>))
        .toList(),
    certificates: (json['certificates'] as List<dynamic>? ?? [])
        .map((c) => Certificate.fromJson(c as Map<String, dynamic>))
        .toList(),
    isAuthenticated: json['is_authenticated'] as bool? ?? false,
    isCounterfeit: json['is_counterfeit'] as bool? ?? false,
    lastVerifiedAt: json['last_verified_at'] != null
        ? DateTime.parse(json['last_verified_at'] as String)
        : null,
    isRecalled: json['is_recalled'] as bool? ?? false,
    recalledAt: json['recalled_at'] != null
        ? DateTime.parse(json['recalled_at'] as String)
        : null,
    recallReason: json['recall_reason'] as String?,
    notes: json['notes'] as String?,
  );

  // movements/coldChainRecords/certificates ne sont jamais écrits ici : ce
  // sont des tables séparées, gérées indépendamment par TraceabilityService.
  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId.isEmpty ? null : productId,
    'product_name': productName,
    'batch_number': batchNumber,
    'serial_number': serialNumber,
    'gtin': gtin,
    'manufacturing_date': manufacturingDate.toIso8601String(),
    'expiry_date': expiryDate.toIso8601String(),
    'status': status.name,
    'manufacturer': manufacturer,
    'manufacturer_id': manufacturerId.isEmpty ? null : manufacturerId,
    'distributor': distributor.isEmpty ? null : distributor,
    'distributor_id': distributorId.isEmpty ? null : distributorId,
    'is_authenticated': isAuthenticated,
    'is_counterfeit': isCounterfeit,
    'last_verified_at': lastVerifiedAt?.toIso8601String(),
    'is_recalled': isRecalled,
    'recalled_at': recalledAt?.toIso8601String(),
    'recall_reason': recallReason,
    'notes': notes,
  };

  TraceableBatch copyWith({
    String? id,
    String? productId,
    String? productName,
    String? batchNumber,
    String? serialNumber,
    String? gtin,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    BatchStatus? status,
    String? manufacturer,
    String? manufacturerId,
    String? distributor,
    String? distributorId,
    List<BatchMovement>? movements,
    List<ColdChainRecord>? coldChainRecords,
    List<Certificate>? certificates,
    bool? isAuthenticated,
    bool? isCounterfeit,
    DateTime? lastVerifiedAt,
    bool? isRecalled,
    DateTime? recalledAt,
    String? recallReason,
    String? notes,
  }) {
    return TraceableBatch(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      batchNumber: batchNumber ?? this.batchNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      gtin: gtin ?? this.gtin,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      manufacturer: manufacturer ?? this.manufacturer,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      distributor: distributor ?? this.distributor,
      distributorId: distributorId ?? this.distributorId,
      movements: movements ?? this.movements,
      coldChainRecords: coldChainRecords ?? this.coldChainRecords,
      certificates: certificates ?? this.certificates,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isCounterfeit: isCounterfeit ?? this.isCounterfeit,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      isRecalled: isRecalled ?? this.isRecalled,
      recalledAt: recalledAt ?? this.recalledAt,
      recallReason: recallReason ?? this.recallReason,
      notes: notes ?? this.notes,
    );
  }

  String get statusLabel {
    switch (status) {
      case BatchStatus.manufactured:
        return 'Fabrication';
      case BatchStatus.inTransit:
        return 'En transit';
      case BatchStatus.atDistributor:
        return 'Chez le grossiste';
      case BatchStatus.atPharmacy:
        return 'En pharmacie';
      case BatchStatus.sold:
        return 'Vendu';
      case BatchStatus.dispensed:
        return 'Dispensé';
      case BatchStatus.returned:
        return 'Retourné';
      case BatchStatus.recalled:
        return 'Rappelé';
      case BatchStatus.destroyed:
        return 'Détruit';
    }
  }

  ColorRole get statusColor {
    switch (status) {
      case BatchStatus.manufactured:
        return ColorRole.secondary;
      case BatchStatus.inTransit:
        return ColorRole.primary;
      case BatchStatus.atDistributor:
        return ColorRole.success;
      case BatchStatus.atPharmacy:
        return ColorRole.warning;
      case BatchStatus.sold:
        return ColorRole.textMuted;
      case BatchStatus.dispensed:
        return ColorRole.success;
      case BatchStatus.returned:
        return ColorRole.textSecondary;
      case BatchStatus.recalled:
        return ColorRole.danger;
      case BatchStatus.destroyed:
        return ColorRole.textMuted;
    }
  }

  String get statusIcon => status.icon;

  bool get isActive =>
      !isRecalled &&
      status != BatchStatus.recalled &&
      status != BatchStatus.destroyed;

  bool get needsVerification => !isRecalled && lastVerifiedAt == null;
}
