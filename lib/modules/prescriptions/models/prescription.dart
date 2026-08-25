import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import 'prescription_item.dart';
import 'prescription_status.dart';

class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String? doctorName;
  final String? doctorLicense;
  final DateTime uploadedAt;
  final DateTime? validatedAt;
  final DateTime? dispensedAt;
  final PrescriptionStatus status;
  final String imageUrl;
  final Map<String, dynamic>? ocrData;
  final String? notes;
  final List<PrescriptionItem> items;
  final double? ocrConfidenceScore;

  Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.doctorName,
    this.doctorLicense,
    required this.uploadedAt,
    this.validatedAt,
    this.dispensedAt,
    required this.status,
    required this.imageUrl,
    this.ocrData,
    this.notes,
    required this.items,
    this.ocrConfidenceScore,
  });

  Prescription copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorName,
    String? doctorLicense,
    DateTime? uploadedAt,
    DateTime? validatedAt,
    DateTime? dispensedAt,
    PrescriptionStatus? status,
    String? imageUrl,
    Map<String, dynamic>? ocrData,
    String? notes,
    List<PrescriptionItem>? items,
    double? ocrConfidenceScore,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      doctorLicense: doctorLicense ?? this.doctorLicense,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      validatedAt: validatedAt ?? this.validatedAt,
      dispensedAt: dispensedAt ?? this.dispensedAt,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      ocrData: ocrData ?? this.ocrData,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      ocrConfidenceScore: ocrConfidenceScore ?? this.ocrConfidenceScore,
    );
  }

  bool get isPending => status == PrescriptionStatus.pending;
  bool get isValidated => status == PrescriptionStatus.validated;
  bool get isDispensed => status == PrescriptionStatus.dispensed;
  bool get isArchived => status == PrescriptionStatus.archived;
  bool get isDraft => status == PrescriptionStatus.draft;

  String get statusLabel {
    switch (status) {
      case PrescriptionStatus.draft:
        return 'Brouillon';
      case PrescriptionStatus.pending:
        return 'En attente';
      case PrescriptionStatus.validated:
        return 'Validée';
      case PrescriptionStatus.dispensed:
        return 'Dispensée';
      case PrescriptionStatus.archived:
        return 'Archivée';
    }
  }

  Color get statusColor {
    switch (status) {
      case PrescriptionStatus.draft:
        return PharmaConnectColors.textSecondary;
      case PrescriptionStatus.pending:
        return PharmaConnectColors.accentOrange;
      case PrescriptionStatus.validated:
        return PharmaConnectColors.accentGreen;
      case PrescriptionStatus.dispensed:
        return PharmaConnectColors.accentCyan;
      case PrescriptionStatus.archived:
        return PharmaConnectColors.neutralMuted;
    }
  }
}
