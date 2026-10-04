import 'package:flutter/material.dart';
import '../../../core/theme/palette.dart';

class VerificationResult {
  final String batchId;
  final String serialNumber;
  final String gtin;
  final bool isAuthentic;
  final bool isCounterfeit;
  final bool isRecalled;
  final bool isValid;
  final DateTime timestamp;
  final String? verifiedBy;
  final String? productName;
  final String? batchNumber;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;
  final String? manufacturer;
  final String? message;
  final VerificationStatus status;

  const VerificationResult({
    required this.batchId,
    required this.serialNumber,
    required this.gtin,
    required this.isAuthentic,
    required this.isCounterfeit,
    required this.isRecalled,
    required this.isValid,
    required this.timestamp,
    this.verifiedBy,
    this.productName,
    this.batchNumber,
    this.manufacturingDate,
    this.expiryDate,
    this.manufacturer,
    this.message,
    required this.status,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) =>
      VerificationResult(
        batchId: json['batch_id'] as String? ?? 'unknown',
        serialNumber: json['serial_number'] as String,
        gtin: json['gtin'] as String,
        isAuthentic: json['is_authentic'] as bool? ?? false,
        isCounterfeit: json['is_counterfeit'] as bool? ?? false,
        isRecalled: json['is_recalled'] as bool? ?? false,
        isValid: json['is_valid'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
        verifiedBy: json['verified_by'] as String?,
        message: json['message'] as String?,
        status: VerificationStatus.values.byName(json['status'] as String),
      );

  // batch_id est une FK uuid nullable : 'unknown' (aucun lot trouvé) n'est
  // pas un uuid valide, jamais écrit tel quel.
  Map<String, dynamic> toJson() => {
    'batch_id': batchId == 'unknown' ? null : batchId,
    'serial_number': serialNumber,
    'gtin': gtin,
    'is_authentic': isAuthentic,
    'is_counterfeit': isCounterfeit,
    'is_recalled': isRecalled,
    'is_valid': isValid,
    'status': status.name,
    'message': message,
    'verified_by': verifiedBy,
    'timestamp': timestamp.toIso8601String(),
  };

  String get statusLabel {
    switch (status) {
      case VerificationStatus.authentic:
        return 'Authentique ✅';
      case VerificationStatus.counterfeit:
        return 'Contrefaçon ❌';
      case VerificationStatus.recalled:
        return 'Rappelé 🔴';
      case VerificationStatus.unknown:
        return 'Inconnu ❓';
      case VerificationStatus.invalid:
        return 'Invalide ⚠️';
    }
  }

  ColorRole get statusColor {
    switch (status) {
      case VerificationStatus.authentic:
        return ColorRole.success;
      case VerificationStatus.counterfeit:
        return ColorRole.danger;
      case VerificationStatus.recalled:
        return ColorRole.warning;
      case VerificationStatus.unknown:
        return ColorRole.textMuted;
      case VerificationStatus.invalid:
        return ColorRole.danger;
    }
  }
}

enum VerificationStatus { authentic, counterfeit, recalled, unknown, invalid }
