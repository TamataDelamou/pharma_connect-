import 'package:equatable/equatable.dart';
import 'triage_status.dart';

class TriagePatient extends Equatable {
  final String id;
  final String patientId;
  final String? triageNurseId;
  final DateTime arrivalTime;
  final TriageStatus status;
  final int priorityLevel; // 1-5 (1=highest)
  final String chiefComplaint;
  final String? symptoms;
  final Map<String, dynamic> vitalSigns;
  final String? notes;
  final String? assignedDepartment;
  final String? assignedDoctorId;
  final String? triageResult;
  final DateTime? dischargedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived fields (from join)
  final String? patientName;
  final String? patientPhone;
  final String? nurseName;
  final String? doctorName;

  const TriagePatient({
    required this.id,
    required this.patientId,
    this.triageNurseId,
    required this.arrivalTime,
    required this.status,
    required this.priorityLevel,
    required this.chiefComplaint,
    this.symptoms,
    this.vitalSigns = const {},
    this.notes,
    this.assignedDepartment,
    this.assignedDoctorId,
    this.triageResult,
    this.dischargedAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
    this.patientPhone,
    this.nurseName,
    this.doctorName,
  });

  TriagePatient copyWith({
    String? id,
    String? patientId,
    String? triageNurseId,
    DateTime? arrivalTime,
    TriageStatus? status,
    int? priorityLevel,
    String? chiefComplaint,
    String? symptoms,
    Map<String, dynamic>? vitalSigns,
    String? notes,
    String? assignedDepartment,
    String? assignedDoctorId,
    String? triageResult,
    DateTime? dischargedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
    String? patientPhone,
    String? nurseName,
    String? doctorName,
  }) {
    return TriagePatient(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      triageNurseId: triageNurseId ?? this.triageNurseId,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      status: status ?? this.status,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      symptoms: symptoms ?? this.symptoms,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      notes: notes ?? this.notes,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
      triageResult: triageResult ?? this.triageResult,
      dischargedAt: dischargedAt ?? this.dischargedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      nurseName: nurseName ?? this.nurseName,
      doctorName: doctorName ?? this.doctorName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    if (triageNurseId != null) 'triage_nurse_id': triageNurseId,
    'arrival_time': arrivalTime.toIso8601String(),
    'status': status.name,
    'priority_level': priorityLevel,
    'chief_complaint': chiefComplaint,
    if (symptoms != null) 'symptoms': symptoms,
    'vital_signs': vitalSigns,
    if (notes != null) 'notes': notes,
    if (assignedDepartment != null) 'assigned_department': assignedDepartment,
    if (assignedDoctorId != null) 'assigned_doctor_id': assignedDoctorId,
    if (triageResult != null) 'triage_result': triageResult,
    if (dischargedAt != null) 'discharged_at': dischargedAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory TriagePatient.fromJson(Map<String, dynamic> json) => TriagePatient(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    triageNurseId: json['triage_nurse_id'] as String?,
    arrivalTime: DateTime.parse(json['arrival_time'] as String),
    status: TriageStatus.values.firstWhere(
      (e) => e.name == (json['status'] as String),
      orElse: () => TriageStatus.waiting,
    ),
    priorityLevel: json['priority_level'] as int,
    chiefComplaint: json['chief_complaint'] as String,
    symptoms: json['symptoms'] as String?,
    vitalSigns: json['vital_signs'] as Map<String, dynamic>? ?? {},
    notes: json['notes'] as String?,
    assignedDepartment: json['assigned_department'] as String?,
    assignedDoctorId: json['assigned_doctor_id'] as String?,
    triageResult: json['triage_result'] as String?,
    dischargedAt: json['discharged_at'] != null
        ? DateTime.parse(json['discharged_at'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    patientName: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    patientPhone: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['phone'] as String?
        : null,
    nurseName: json['nurses'] != null
        ? (json['nurses'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    doctorName: json['doctors'] != null
        ? (json['doctors'] as Map<String, dynamic>)['full_name'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    triageNurseId,
    arrivalTime,
    status,
    priorityLevel,
    chiefComplaint,
    symptoms,
    vitalSigns,
    notes,
    assignedDepartment,
    assignedDoctorId,
    triageResult,
    dischargedAt,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
    patientPhone,
    nurseName,
    doctorName,
  ];
}
