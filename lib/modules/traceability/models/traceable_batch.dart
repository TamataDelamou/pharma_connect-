import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'batch_status.dart';
import 'batch_movement.dart';
import 'cold_chain_record.dart';
import 'certificate.dart';

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

  Color get statusColor {
    switch (status) {
      case BatchStatus.manufactured:
        return PharmaConnectColors.accentPurple;
      case BatchStatus.inTransit:
        return PharmaConnectColors.accentCyan;
      case BatchStatus.atDistributor:
        return PharmaConnectColors.accentGreen;
      case BatchStatus.atPharmacy:
        return PharmaConnectColors.accentOrange;
      case BatchStatus.sold:
        return PharmaConnectColors.neutralMuted;
      case BatchStatus.dispensed:
        return PharmaConnectColors.accentGreen;
      case BatchStatus.returned:
        return PharmaConnectColors.textSecondary;
      case BatchStatus.recalled:
        return PharmaConnectColors.accentRed;
      case BatchStatus.destroyed:
        return PharmaConnectColors.neutralDark;
    }
  }

  String get statusIcon => status.icon;

  bool get isActive =>
      !isRecalled &&
      status != BatchStatus.recalled &&
      status != BatchStatus.destroyed;

  bool get needsVerification => !isRecalled && lastVerifiedAt == null;
}
