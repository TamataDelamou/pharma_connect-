import 'package:equatable/equatable.dart';

class TriageAIAnalysis extends Equatable {
  final String id;
  final String triagePatientId;
  final String symptoms;
  final int priorityScore;
  final String? suggestedDepartment;
  final bool isCritical;
  final Map<String, dynamic> analysisDetails;
  final int? actualPriority;
  final String? actualDepartment;
  final String? doctorFeedback;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const TriageAIAnalysis({
    required this.id,
    required this.triagePatientId,
    required this.symptoms,
    required this.priorityScore,
    this.suggestedDepartment,
    this.isCritical = false,
    this.analysisDetails = const {},
    this.actualPriority,
    this.actualDepartment,
    this.doctorFeedback,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  TriageAIAnalysis copyWith({
    String? id,
    String? triagePatientId,
    String? symptoms,
    int? priorityScore,
    String? suggestedDepartment,
    bool? isCritical,
    Map<String, dynamic>? analysisDetails,
    int? actualPriority,
    String? actualDepartment,
    String? doctorFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return TriageAIAnalysis(
      id: id ?? this.id,
      triagePatientId: triagePatientId ?? this.triagePatientId,
      symptoms: symptoms ?? this.symptoms,
      priorityScore: priorityScore ?? this.priorityScore,
      suggestedDepartment: suggestedDepartment ?? this.suggestedDepartment,
      isCritical: isCritical ?? this.isCritical,
      analysisDetails: analysisDetails ?? this.analysisDetails,
      actualPriority: actualPriority ?? this.actualPriority,
      actualDepartment: actualDepartment ?? this.actualDepartment,
      doctorFeedback: doctorFeedback ?? this.doctorFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'triage_patient_id': triagePatientId,
    'symptoms': symptoms,
    'priority_score': priorityScore,
    if (suggestedDepartment != null)
      'suggested_department': suggestedDepartment,
    'is_critical': isCritical,
    'analysis_details': analysisDetails,
    if (actualPriority != null) 'actual_priority': actualPriority,
    if (actualDepartment != null) 'actual_department': actualDepartment,
    if (doctorFeedback != null) 'doctor_feedback': doctorFeedback,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory TriageAIAnalysis.fromJson(Map<String, dynamic> json) =>
      TriageAIAnalysis(
        id: json['id'] as String,
        triagePatientId: json['triage_patient_id'] as String,
        symptoms: json['symptoms'] as String,
        priorityScore: json['priority_score'] as int,
        suggestedDepartment: json['suggested_department'] as String?,
        isCritical: json['is_critical'] as bool? ?? false,
        analysisDetails:
            json['analysis_details'] as Map<String, dynamic>? ?? {},
        actualPriority: json['actual_priority'] as int?,
        actualDepartment: json['actual_department'] as String?,
        doctorFeedback: json['doctor_feedback'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    triagePatientId,
    symptoms,
    priorityScore,
    suggestedDepartment,
    isCritical,
    analysisDetails,
    actualPriority,
    actualDepartment,
    doctorFeedback,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get priorityLabel {
    switch (priorityScore) {
      case 1:
        return '🔴 Critique - Immédiat';
      case 2:
        return '🟠 Urgent';
      case 3:
        return '🟡 Modéré';
      case 4:
        return '🟢 Léger';
      case 5:
        return '🔵 Non urgent';
      default:
        return 'Non déterminé';
    }
  }
}
