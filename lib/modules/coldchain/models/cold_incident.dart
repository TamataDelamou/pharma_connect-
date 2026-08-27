import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

enum IncidentSeverity { critical, major, minor }

class ColdIncident {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String batchId;
  final String batchNumber;
  final String productName;
  final DateTime occurredAt;
  final DateTime? resolvedAt;
  final double temperatureRecorded;
  final double minTemperature;
  final double maxTemperature;
  final IncidentSeverity severity;
  final String? resolutionNotes;
  final String? reportedBy;
  final bool isResolved;
  final String? affectedProducts;

  ColdIncident({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.batchId,
    required this.batchNumber,
    required this.productName,
    required this.occurredAt,
    this.resolvedAt,
    required this.temperatureRecorded,
    required this.minTemperature,
    required this.maxTemperature,
    required this.severity,
    this.resolutionNotes,
    this.reportedBy,
    this.isResolved = false,
    this.affectedProducts,
  });

  ColdIncident copyWith({
    String? id,
    String? equipmentId,
    String? equipmentName,
    String? batchId,
    String? batchNumber,
    String? productName,
    DateTime? occurredAt,
    DateTime? resolvedAt,
    double? temperatureRecorded,
    double? minTemperature,
    double? maxTemperature,
    IncidentSeverity? severity,
    String? resolutionNotes,
    String? reportedBy,
    bool? isResolved,
    String? affectedProducts,
  }) {
    return ColdIncident(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      batchId: batchId ?? this.batchId,
      batchNumber: batchNumber ?? this.batchNumber,
      productName: productName ?? this.productName,
      occurredAt: occurredAt ?? this.occurredAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      temperatureRecorded: temperatureRecorded ?? this.temperatureRecorded,
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      severity: severity ?? this.severity,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      reportedBy: reportedBy ?? this.reportedBy,
      isResolved: isResolved ?? this.isResolved,
      affectedProducts: affectedProducts ?? this.affectedProducts,
    );
  }

  String get severityLabel {
    switch (severity) {
      case IncidentSeverity.critical:
        return 'Critique';
      case IncidentSeverity.major:
        return 'Majeure';
      case IncidentSeverity.minor:
        return 'Mineure';
    }
  }

  Color get severityColor {
    switch (severity) {
      case IncidentSeverity.critical:
        return PharmaConnectColors.accentRed;
      case IncidentSeverity.major:
        return PharmaConnectColors.accentOrange;
      case IncidentSeverity.minor:
        return PharmaConnectColors.accentAmber;
    }
  }

  String get duration {
    if (resolvedAt == null) return 'En cours';
    final diff = resolvedAt!.difference(occurredAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}min';
    return '${diff.inDays}j ${diff.inHours % 24}h';
  }
}
