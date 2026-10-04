import 'package:flutter/material.dart';
import 'recall_severity.dart';
import 'recall_status.dart';
import 'recall_affected_batch.dart';
import '../../../core/theme/palette.dart';

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

  factory Recall.fromJson(Map<String, dynamic> json) => Recall(
    id: json['id'] as String,
    referenceNumber: json['reference_number'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    severity: RecallSeverity.values.byName(json['severity'] as String),
    status: RecallStatus.values.byName(json['status'] as String),
    affectedBatches: (json['recall_affected_batches'] as List<dynamic>? ?? [])
        .map((b) => RecallAffectedBatch.fromJson(b as Map<String, dynamic>))
        .toList(),
    issuedAt: DateTime.parse(json['issued_at'] as String),
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String)
        : null,
    issuedBy: json['issued_by'] as String,
    issuedByUserId: json['issued_by_user_id'] as String?,
    reason: json['reason'] as String?,
    correctiveAction: json['corrective_action'] as String?,
    distributionInstructions: json['distribution_instructions'] as String?,
    isPublic: json['is_public'] as bool? ?? true,
    totalAffectedUnits: json['total_affected_units'] as int?,
    unitsReturned: json['units_returned'] as int?,
    unitsDestroyed: json['units_destroyed'] as int?,
    unitsUnrecovered: json['units_unrecovered'] as int?,
    notifiedParties: (json['notified_parties'] as List<dynamic>?)
        ?.map((p) => p as String)
        .toList(),
    notes: json['notes'] as String?,
  );

  // affectedBatches n'est jamais écrit ici : recall_affected_batches est une
  // table séparée, insérée/mise à jour indépendamment par RecallService.
  Map<String, dynamic> toJson() => {
    'id': id,
    'reference_number': referenceNumber,
    'title': title,
    'description': description,
    'severity': severity.name,
    'status': status.name,
    'issued_at': issuedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'issued_by': issuedBy,
    'issued_by_user_id': issuedByUserId,
    'reason': reason,
    'corrective_action': correctiveAction,
    'distribution_instructions': distributionInstructions,
    'is_public': isPublic,
    'total_affected_units': totalAffectedUnits,
    'units_returned': unitsReturned,
    'units_destroyed': unitsDestroyed,
    'units_unrecovered': unitsUnrecovered,
    'notified_parties': notifiedParties,
    'notes': notes,
  };

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

  ColorRole get statusColor {
    switch (status) {
      case RecallStatus.draft:
        return ColorRole.textMuted;
      case RecallStatus.inProgress:
        return ColorRole.warning;
      case RecallStatus.completed:
        return ColorRole.success;
      case RecallStatus.cancelled:
        return ColorRole.danger;
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

  ColorRole get severityColor {
    switch (severity) {
      case RecallSeverity.classI:
        return ColorRole.danger;
      case RecallSeverity.classII:
        return ColorRole.warning;
      case RecallSeverity.classIII:
        return ColorRole.warningStrong;
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
