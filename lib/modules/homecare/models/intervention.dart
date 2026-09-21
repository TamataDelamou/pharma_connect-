import 'package:equatable/equatable.dart';
import 'homecare_status.dart';

class Intervention extends Equatable {
  final String id;
  final String patientId;
  final String professionalId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final HomecareStatus status;
  final String reason;
  final String address;
  final String? notes;
  final String? report;
  final String? refusalReason;
  final String? patientFeedback;
  final int? patientRating;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived fields (from join)
  final String? patientName;
  final String? patientPhone;
  final String? professionalName;
  final String? professionalSpecialty;

  const Intervention({
    required this.id,
    required this.patientId,
    required this.professionalId,
    required this.scheduledAt,
    this.durationMinutes = 60,
    required this.status,
    required this.reason,
    required this.address,
    this.notes,
    this.report,
    this.refusalReason,
    this.patientFeedback,
    this.patientRating,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
    this.patientPhone,
    this.professionalName,
    this.professionalSpecialty,
  });

  Intervention copyWith({
    String? id,
    String? patientId,
    String? professionalId,
    DateTime? scheduledAt,
    int? durationMinutes,
    HomecareStatus? status,
    String? reason,
    String? address,
    String? notes,
    String? report,
    String? refusalReason,
    String? patientFeedback,
    int? patientRating,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
    String? patientPhone,
    String? professionalName,
    String? professionalSpecialty,
  }) {
    return Intervention(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      professionalId: professionalId ?? this.professionalId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      report: report ?? this.report,
      refusalReason: refusalReason ?? this.refusalReason,
      patientFeedback: patientFeedback ?? this.patientFeedback,
      patientRating: patientRating ?? this.patientRating,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      professionalName: professionalName ?? this.professionalName,
      professionalSpecialty:
          professionalSpecialty ?? this.professionalSpecialty,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'professional_id': professionalId,
    'scheduled_at': scheduledAt.toIso8601String(),
    'duration_minutes': durationMinutes,
    // Audit Module 18 (HOM, 30/08/2026) : `status.name` renvoyait
    // 'inProgress' (camelCase Dart), incompatible avec la contrainte CHECK
    // SQL ('in_progress', snake_case) — voir homecare_status.dart.
    'status': status.dbValue,
    'reason': reason,
    'address': address,
    if (notes != null) 'notes': notes,
    if (report != null) 'report': report,
    if (refusalReason != null) 'refusal_reason': refusalReason,
    if (patientFeedback != null) 'patient_feedback': patientFeedback,
    if (patientRating != null) 'patient_rating': patientRating,
    if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
    if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory Intervention.fromJson(Map<String, dynamic> json) => Intervention(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    professionalId: json['professional_id'] as String,
    scheduledAt: DateTime.parse(json['scheduled_at'] as String),
    durationMinutes: json['duration_minutes'] as int? ?? 60,
    status: homecareStatusFromDb(json['status'] as String),
    reason: json['reason'] as String? ?? '',
    address: json['address'] as String,
    notes: json['notes'] as String?,
    report: json['report'] as String?,
    refusalReason: json['refusal_reason'] as String?,
    patientFeedback: json['patient_feedback'] as String?,
    patientRating: json['patient_rating'] as int?,
    startedAt: json['started_at'] != null
        ? DateTime.parse(json['started_at'] as String)
        : null,
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String)
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
    professionalName: json['professionals'] != null
        ? (json['professionals'] as Map<String, dynamic>)['full_name']
              as String?
        : null,
    professionalSpecialty: json['professionals'] != null
        ? (json['professionals'] as Map<String, dynamic>)['specialty']
              as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    professionalId,
    scheduledAt,
    durationMinutes,
    status,
    reason,
    address,
    notes,
    report,
    refusalReason,
    patientFeedback,
    patientRating,
    startedAt,
    completedAt,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
    patientPhone,
    professionalName,
    professionalSpecialty,
  ];
}
