import 'package:flutter/material.dart';

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

  Color get statusColor {
    switch (status) {
      case VerificationStatus.authentic:
        return Colors.green;
      case VerificationStatus.counterfeit:
        return Colors.red;
      case VerificationStatus.recalled:
        return Colors.orange;
      case VerificationStatus.unknown:
        return Colors.grey;
      case VerificationStatus.invalid:
        return Colors.red;
    }
  }
}

enum VerificationStatus { authentic, counterfeit, recalled, unknown, invalid }
