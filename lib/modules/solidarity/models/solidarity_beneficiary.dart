import 'package:equatable/equatable.dart';

class SolidarityBeneficiary extends Equatable {
  final String id;
  final String patientId;
  final String programId;
  final DateTime enrollmentDate;
  final String status; // active, completed, suspended, expired
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? patientName;
  final String? programName;

  const SolidarityBeneficiary({
    required this.id,
    required this.patientId,
    required this.programId,
    required this.enrollmentDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
    this.programName,
  });

  SolidarityBeneficiary copyWith({
    String? id,
    String? patientId,
    String? programId,
    DateTime? enrollmentDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
    String? programName,
  }) => SolidarityBeneficiary(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    programId: programId ?? this.programId,
    enrollmentDate: enrollmentDate ?? this.enrollmentDate,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    gsgId: gsgId ?? this.gsgId,
    gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    patientName: patientName ?? this.patientName,
    programName: programName ?? this.programName,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'program_id': programId,
    'enrollment_date': enrollmentDate.toIso8601String(),
    'status': status,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory SolidarityBeneficiary.fromJson(Map<String, dynamic> json) =>
      SolidarityBeneficiary(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        programId: json['program_id'] as String,
        enrollmentDate: DateTime.parse(json['enrollment_date'] as String),
        status: json['status'] as String,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
        patientName: json['patients'] != null
            ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
            : null,
        programName: json['programs'] != null
            ? (json['programs'] as Map<String, dynamic>)['name'] as String?
            : null,
      );

  @override
  List<Object?> get props => [
    id,
    patientId,
    programId,
    enrollmentDate,
    status,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
    programName,
  ];

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      case 'suspended':
        return 'Suspendu';
      case 'expired':
        return 'Expiré';
      default:
        return status;
    }
  }

  bool get isActive => status == 'active';
}
