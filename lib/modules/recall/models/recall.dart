import 'package:flutter/material.dart';
import 'recall_severity.dart';
import 'recall_status.dart';
import 'recall_affected_batch.dart';

class Recall {
  final String id;
  final String referenceNumber;
  final String title;
  final String description;
  final RecallSeverity severity;
  final RecallStatus status;
  final List<RecallAffectedBatch> affectedBatches;
  final DateTime issuedAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String issuedBy;
  final String? issuedByUserId;
  final String? reason;
  final String? correctiveAction;
  final String? distributionInstructions;
  final bool isPublic;
  final int? totalAffectedUnits;
  final int? unitsReturned;
  final int? unitsDestroyed;
  final int? unitsUnrecovered;
  final List<String>? notifiedParties;
  final String? notes;

  Recall({
    required this.id,
    required this.referenceNumber,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.affectedBatches,
    required this.issuedAt,
    this.updatedAt,
    this.completedAt,
    required this.issuedBy,
    this.issuedByUserId,
    this.reason,
    this.correctiveAction,
    this.distributionInstructions,
    this.isPublic = true,
    this.totalAffectedUnits,
    this.unitsReturned,
    this.unitsDestroyed,
    this.unitsUnrecovered,
    this.notifiedParties,
    this.notes,
  });

  Recall copyWith({
    String? id,
    String? referenceNumber,
    String? title,
    String? description,
    RecallSeverity? severity,
    RecallStatus? status,
    List<RecallAffectedBatch>? affectedBatches,
    DateTime? issuedAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? issuedBy,
    String? issuedByUserId,
    String? reason,
    String? correctiveAction,
    String? distributionInstructions,
    bool? isPublic,
    int? totalAffectedUnits,
    int? unitsReturned,
    int? unitsDestroyed,
    int? unitsUnrecovered,
    List<String>? notifiedParties,
    String? notes,
  }) {
    return Recall(
      id: id ?? this.id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      affectedBatches: affectedBatches ?? this.affectedBatches,
      issuedAt: issuedAt ?? this.issuedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      issuedBy: issuedBy ?? this.issuedBy,
      issuedByUserId: issuedByUserId ?? this.issuedByUserId,
      reason: reason ?? this.reason,
      correctiveAction: correctiveAction ?? this.correctiveAction,
      distributionInstructions:
          distributionInstructions ?? this.distributionInstructions,
      isPublic: isPublic ?? this.isPublic,
      totalAffectedUnits: totalAffectedUnits ?? this.totalAffectedUnits,
      unitsReturned: unitsReturned ?? this.unitsReturned,
      unitsDestroyed: unitsDestroyed ?? this.unitsDestroyed,
      unitsUnrecovered: unitsUnrecovered ?? this.unitsUnrecovered,
      notifiedParties: notifiedParties ?? this.notifiedParties,
      notes: notes ?? this.notes,
    );
  }

  String get statusLabel {
    switch (status) {
      case RecallStatus.draft:
        return 'Brouillon';
      case RecallStatus.inProgress:
        return 'En cours';
      case RecallStatus.completed:
        return 'Terminé';
      case RecallStatus.cancelled:
        return 'Annulé';
    }
  }

  Color get statusColor {
    switch (status) {
      case RecallStatus.draft:
        return Colors.grey;
      case RecallStatus.inProgress:
        return Colors.orange;
      case RecallStatus.completed:
        return Colors.green;
      case RecallStatus.cancelled:
        return Colors.red;
    }
  }

  String get severityLabel {
    switch (severity) {
      case RecallSeverity.classI:
        return 'Classe I (Urgent)';
      case RecallSeverity.classII:
        return 'Classe II (Moyen)';
      case RecallSeverity.classIII:
        return 'Classe III (Faible)';
    }
  }

  Color get severityColor {
    switch (severity) {
      case RecallSeverity.classI:
        return Colors.red;
      case RecallSeverity.classII:
        return Colors.orange;
      case RecallSeverity.classIII:
        return Colors.yellow;
    }
  }

  String get severityIcon {
    switch (severity) {
      case RecallSeverity.classI:
        return '🔴';
      case RecallSeverity.classII:
        return '🟡';
      case RecallSeverity.classIII:
        return '🔵';
    }
  }

  double get completionRate {
    if (totalAffectedUnits == null || totalAffectedUnits == 0) return 0;
    final recovered = (unitsReturned ?? 0) + (unitsDestroyed ?? 0);
    return recovered / totalAffectedUnits!;
  }

  bool get isActive => status == RecallStatus.inProgress;
  bool get isCompleted => status == RecallStatus.completed;
  bool get isEditable => status == RecallStatus.draft;
}
