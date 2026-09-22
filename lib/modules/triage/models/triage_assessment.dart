import 'package:equatable/equatable.dart';

class TriageAssessment extends Equatable {
  final String id;
  final String triagePatientId;
  final String nurseId;
  final DateTime assessmentTime;
  final int? painScore;
  final int? respiratoryRate;
  final int? heartRate;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final double? temperature;
  final int? oxygenSaturation;
  final String? consciousnessLevel; // alert, verbal, pain, unresponsive
  final String?
  triageCategory; // resuscitation, emergency, urgent, semi-urgent, non-urgent
  final String? recommendations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived fields
  final String? nurseName;

  const TriageAssessment({
    required this.id,
    required this.triagePatientId,
    required this.nurseId,
    required this.assessmentTime,
    this.painScore,
    this.respiratoryRate,
    this.heartRate,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.temperature,
    this.oxygenSaturation,
    this.consciousnessLevel,
    this.triageCategory,
    this.recommendations,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.nurseName,
  });

  TriageAssessment copyWith({
    String? id,
    String? triagePatientId,
    String? nurseId,
    DateTime? assessmentTime,
    int? painScore,
    int? respiratoryRate,
    int? heartRate,
    int? bloodPressureSystolic,
    int? bloodPressureDiastolic,
    double? temperature,
    int? oxygenSaturation,
    String? consciousnessLevel,
    String? triageCategory,
    String? recommendations,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? nurseName,
  }) {
    return TriageAssessment(
      id: id ?? this.id,
      triagePatientId: triagePatientId ?? this.triagePatientId,
      nurseId: nurseId ?? this.nurseId,
      assessmentTime: assessmentTime ?? this.assessmentTime,
      painScore: painScore ?? this.painScore,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      heartRate: heartRate ?? this.heartRate,
      bloodPressureSystolic:
          bloodPressureSystolic ?? this.bloodPressureSystolic,
      bloodPressureDiastolic:
          bloodPressureDiastolic ?? this.bloodPressureDiastolic,
      temperature: temperature ?? this.temperature,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      consciousnessLevel: consciousnessLevel ?? this.consciousnessLevel,
      triageCategory: triageCategory ?? this.triageCategory,
      recommendations: recommendations ?? this.recommendations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      nurseName: nurseName ?? this.nurseName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'triage_patient_id': triagePatientId,
    'nurse_id': nurseId,
    'assessment_time': assessmentTime.toIso8601String(),
    if (painScore != null) 'pain_score': painScore,
    if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
    if (heartRate != null) 'heart_rate': heartRate,
    if (bloodPressureSystolic != null)
      'blood_pressure_systolic': bloodPressureSystolic,
    if (bloodPressureDiastolic != null)
      'blood_pressure_diastolic': bloodPressureDiastolic,
    if (temperature != null) 'temperature': temperature,
    if (oxygenSaturation != null) 'oxygen_saturation': oxygenSaturation,
    if (consciousnessLevel != null) 'consciousness_level': consciousnessLevel,
    if (triageCategory != null) 'triage_category': triageCategory,
    if (recommendations != null) 'recommendations': recommendations,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory TriageAssessment.fromJson(Map<String, dynamic> json) =>
      TriageAssessment(
        id: json['id'] as String,
        triagePatientId: json['triage_patient_id'] as String,
        nurseId: json['nurse_id'] as String,
        assessmentTime: DateTime.parse(json['assessment_time'] as String),
        painScore: json['pain_score'] as int?,
        respiratoryRate: json['respiratory_rate'] as int?,
        heartRate: json['heart_rate'] as int?,
        bloodPressureSystolic: json['blood_pressure_systolic'] as int?,
        bloodPressureDiastolic: json['blood_pressure_diastolic'] as int?,
        temperature: (json['temperature'] as num?)?.toDouble(),
        oxygenSaturation: json['oxygen_saturation'] as int?,
        consciousnessLevel: json['consciousness_level'] as String?,
        triageCategory: json['triage_category'] as String?,
        recommendations: json['recommendations'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
        nurseName: json['nurses'] != null
            ? (json['nurses'] as Map<String, dynamic>)['full_name'] as String?
            : null,
      );

  @override
  List<Object?> get props => [
    id,
    triagePatientId,
    nurseId,
    assessmentTime,
    painScore,
    respiratoryRate,
    heartRate,
    bloodPressureSystolic,
    bloodPressureDiastolic,
    temperature,
    oxygenSaturation,
    consciousnessLevel,
    triageCategory,
    recommendations,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    nurseName,
  ];
}
