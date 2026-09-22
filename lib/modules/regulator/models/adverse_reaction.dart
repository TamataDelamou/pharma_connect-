import 'package:equatable/equatable.dart';

class AdverseReaction extends Equatable {
  final String id;
  final String? patientId;
  final String reporterId;
  final String reporterType; // patient, pharmacist, doctor, nurse, other
  final String? medicationId;
  final String medicationName;
  final DateTime reactionDate;
  final DateTime reportedAt;
  final String symptoms;
  final String severity; // mild, moderate, severe, life_threatening
  final String?
  outcome; // recovered, recovering, ongoing, permanent_damage, death
  final bool treatmentRequired;
  final bool hospitalizationRequired;
  final String? notes;
  final String status; // pending, under_review, investigating, closed, rejected
  final String? followUpNotes;
  final String? regulatoryAction;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? patientName;
  final String? reporterName;
  final String? medicationGenericName;

  const AdverseReaction({
    required this.id,
    this.patientId,
    required this.reporterId,
    required this.reporterType,
    this.medicationId,
    required this.medicationName,
    required this.reactionDate,
    required this.reportedAt,
    required this.symptoms,
    required this.severity,
    this.outcome,
    this.treatmentRequired = false,
    this.hospitalizationRequired = false,
    this.notes,
    required this.status,
    this.followUpNotes,
    this.regulatoryAction,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
    this.reporterName,
    this.medicationGenericName,
  });

  AdverseReaction copyWith({
    String? id,
    String? patientId,
    String? reporterId,
    String? reporterType,
    String? medicationId,
    String? medicationName,
    DateTime? reactionDate,
    DateTime? reportedAt,
    String? symptoms,
    String? severity,
    String? outcome,
    bool? treatmentRequired,
    bool? hospitalizationRequired,
    String? notes,
    String? status,
    String? followUpNotes,
    String? regulatoryAction,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
    String? reporterName,
    String? medicationGenericName,
  }) {
    return AdverseReaction(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      reporterId: reporterId ?? this.reporterId,
      reporterType: reporterType ?? this.reporterType,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      reactionDate: reactionDate ?? this.reactionDate,
      reportedAt: reportedAt ?? this.reportedAt,
      symptoms: symptoms ?? this.symptoms,
      severity: severity ?? this.severity,
      outcome: outcome ?? this.outcome,
      treatmentRequired: treatmentRequired ?? this.treatmentRequired,
      hospitalizationRequired:
          hospitalizationRequired ?? this.hospitalizationRequired,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      regulatoryAction: regulatoryAction ?? this.regulatoryAction,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
      reporterName: reporterName ?? this.reporterName,
      medicationGenericName:
          medicationGenericName ?? this.medicationGenericName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (patientId != null) 'patient_id': patientId,
    'reporter_id': reporterId,
    'reporter_type': reporterType,
    if (medicationId != null) 'medication_id': medicationId,
    'medication_name': medicationName,
    'reaction_date': reactionDate.toIso8601String(),
    'reported_at': reportedAt.toIso8601String(),
    'symptoms': symptoms,
    'severity': severity,
    if (outcome != null) 'outcome': outcome,
    'treatment_required': treatmentRequired,
    'hospitalization_required': hospitalizationRequired,
    if (notes != null) 'notes': notes,
    'status': status,
    if (followUpNotes != null) 'follow_up_notes': followUpNotes,
    if (regulatoryAction != null) 'regulatory_action': regulatoryAction,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory AdverseReaction.fromJson(
    Map<String, dynamic> json,
  ) => AdverseReaction(
    id: json['id'] as String,
    patientId: json['patient_id'] as String?,
    reporterId: json['reporter_id'] as String,
    reporterType: json['reporter_type'] as String,
    medicationId: json['medication_id'] as String?,
    medicationName: json['medication_name'] as String,
    reactionDate: DateTime.parse(json['reaction_date'] as String),
    reportedAt: DateTime.parse(json['reported_at'] as String),
    symptoms: json['symptoms'] as String,
    severity: json['severity'] as String,
    outcome: json['outcome'] as String?,
    treatmentRequired: json['treatment_required'] as bool? ?? false,
    hospitalizationRequired: json['hospitalization_required'] as bool? ?? false,
    notes: json['notes'] as String?,
    status: json['status'] as String,
    followUpNotes: json['follow_up_notes'] as String?,
    regulatoryAction: json['regulatory_action'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    patientName: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    reporterName: json['reporters'] != null
        ? (json['reporters'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    medicationGenericName: json['products'] != null
        ? (json['products'] as Map<String, dynamic>)['generic_name'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    reporterId,
    reporterType,
    medicationId,
    medicationName,
    reactionDate,
    reportedAt,
    symptoms,
    severity,
    outcome,
    treatmentRequired,
    hospitalizationRequired,
    notes,
    status,
    followUpNotes,
    regulatoryAction,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
    reporterName,
    medicationGenericName,
  ];

  String get severityLabel {
    switch (severity) {
      case 'mild':
        return 'Léger';
      case 'moderate':
        return 'Modéré';
      case 'severe':
        return 'Sévère';
      case 'life_threatening':
        return 'Engage le pronostic vital';
      default:
        return severity;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'under_review':
        return 'En cours d\'examen';
      case 'investigating':
        return 'En investigation';
      case 'closed':
        return 'Clos';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }
}
