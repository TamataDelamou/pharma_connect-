import 'package:equatable/equatable.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4 : modèle pour la table
// `regulatory_inspections`, jusqu'ici entièrement orpheline (aucun modèle,
// service, provider ni écran ne l'exposait).
class RegulatoryInspection extends Equatable {
  final String id;
  final String entityType; // pharmacy, hospital, laboratory, manufacturer, wholesaler
  final String entityId;
  final String? inspectorId;
  final DateTime inspectionDate;
  final String type; // routine, complaint, follow_up, emergency
  final String status; // scheduled, in_progress, completed, cancelled
  final String? findings;
  final List<String> violations;
  final String? recommendations;
  final String? actionTaken;
  final DateTime? followUpDate;
  final String? reportUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  // Derived
  final String? inspectorName;

  const RegulatoryInspection({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.inspectorId,
    required this.inspectionDate,
    required this.type,
    required this.status,
    this.findings,
    this.violations = const [],
    this.recommendations,
    this.actionTaken,
    this.followUpDate,
    this.reportUrl,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.inspectorName,
  });

  RegulatoryInspection copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? inspectorId,
    DateTime? inspectionDate,
    String? type,
    String? status,
    String? findings,
    List<String>? violations,
    String? recommendations,
    String? actionTaken,
    DateTime? followUpDate,
    String? reportUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? inspectorName,
  }) {
    return RegulatoryInspection(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      type: type ?? this.type,
      status: status ?? this.status,
      findings: findings ?? this.findings,
      violations: violations ?? this.violations,
      recommendations: recommendations ?? this.recommendations,
      actionTaken: actionTaken ?? this.actionTaken,
      followUpDate: followUpDate ?? this.followUpDate,
      reportUrl: reportUrl ?? this.reportUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      inspectorName: inspectorName ?? this.inspectorName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'entity_type': entityType,
    'entity_id': entityId,
    if (inspectorId != null) 'inspector_id': inspectorId,
    'inspection_date': inspectionDate.toIso8601String(),
    'type': type,
    'status': status,
    if (findings != null) 'findings': findings,
    'violations': violations,
    if (recommendations != null) 'recommendations': recommendations,
    if (actionTaken != null) 'action_taken': actionTaken,
    if (followUpDate != null) 'follow_up_date': followUpDate!.toIso8601String(),
    if (reportUrl != null) 'report_url': reportUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
  };

  factory RegulatoryInspection.fromJson(Map<String, dynamic> json) =>
      RegulatoryInspection(
        id: json['id'] as String,
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String,
        inspectorId: json['inspector_id'] as String?,
        inspectionDate: DateTime.parse(json['inspection_date'] as String),
        type: json['type'] as String,
        status: json['status'] as String,
        findings: json['findings'] as String?,
        violations:
            (json['violations'] as List?)?.map((e) => e as String).toList() ??
            const [],
        recommendations: json['recommendations'] as String?,
        actionTaken: json['action_taken'] as String?,
        followUpDate: json['follow_up_date'] != null
            ? DateTime.parse(json['follow_up_date'] as String)
            : null,
        reportUrl: json['report_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        inspectorName: json['inspectors'] != null
            ? (json['inspectors'] as Map<String, dynamic>)['full_name']
                  as String?
            : null,
      );

  @override
  List<Object?> get props => [
    id,
    entityType,
    entityId,
    inspectorId,
    inspectionDate,
    type,
    status,
    findings,
    violations,
    recommendations,
    actionTaken,
    followUpDate,
    reportUrl,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    inspectorName,
  ];

  String get entityTypeLabel {
    switch (entityType) {
      case 'pharmacy':
        return 'Officine';
      case 'hospital':
        return 'Hôpital';
      case 'laboratory':
        return 'Laboratoire';
      case 'manufacturer':
        return 'Fabricant';
      case 'wholesaler':
        return 'Grossiste';
      default:
        return entityType;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'routine':
        return 'Routine';
      case 'complaint':
        return 'Plainte';
      case 'follow_up':
        return 'Suivi';
      case 'emergency':
        return 'Urgence';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'scheduled':
        return 'Planifiée';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}
