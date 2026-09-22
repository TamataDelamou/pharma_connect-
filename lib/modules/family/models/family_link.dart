import 'package:equatable/equatable.dart';
import 'family_link_status.dart';

class FamilyLink extends Equatable {
  final String id;
  final String patientId;
  final String familyMemberId;
  final String relationship;
  final bool canViewRecords;
  final bool canViewPrescriptions;
  final bool canBookConsultations;
  final bool canReceiveAlerts;
  final FamilyLinkStatus status;
  final DateTime invitedAt;
  final DateTime? activatedAt;
  final DateTime? revokedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived fields (from join)
  final String? patientName;
  final String? patientPhone;
  final String? familyMemberName;
  final String? familyMemberPhone;

  const FamilyLink({
    required this.id,
    required this.patientId,
    required this.familyMemberId,
    required this.relationship,
    this.canViewRecords = true,
    this.canViewPrescriptions = true,
    this.canBookConsultations = false,
    this.canReceiveAlerts = true,
    required this.status,
    required this.invitedAt,
    this.activatedAt,
    this.revokedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
    this.patientPhone,
    this.familyMemberName,
    this.familyMemberPhone,
  });

  FamilyLink copyWith({
    String? id,
    String? patientId,
    String? familyMemberId,
    String? relationship,
    bool? canViewRecords,
    bool? canViewPrescriptions,
    bool? canBookConsultations,
    bool? canReceiveAlerts,
    FamilyLinkStatus? status,
    DateTime? invitedAt,
    DateTime? activatedAt,
    DateTime? revokedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
    String? patientPhone,
    String? familyMemberName,
    String? familyMemberPhone,
  }) {
    return FamilyLink(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      relationship: relationship ?? this.relationship,
      canViewRecords: canViewRecords ?? this.canViewRecords,
      canViewPrescriptions: canViewPrescriptions ?? this.canViewPrescriptions,
      canBookConsultations: canBookConsultations ?? this.canBookConsultations,
      canReceiveAlerts: canReceiveAlerts ?? this.canReceiveAlerts,
      status: status ?? this.status,
      invitedAt: invitedAt ?? this.invitedAt,
      activatedAt: activatedAt ?? this.activatedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      familyMemberName: familyMemberName ?? this.familyMemberName,
      familyMemberPhone: familyMemberPhone ?? this.familyMemberPhone,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'family_member_id': familyMemberId,
    'relationship': relationship,
    'can_view_records': canViewRecords,
    'can_view_prescriptions': canViewPrescriptions,
    'can_book_consultations': canBookConsultations,
    'can_receive_alerts': canReceiveAlerts,
    'status': status.name,
    'invited_at': invitedAt.toIso8601String(),
    if (activatedAt != null) 'activated_at': activatedAt!.toIso8601String(),
    if (revokedAt != null) 'revoked_at': revokedAt!.toIso8601String(),
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory FamilyLink.fromJson(Map<String, dynamic> json) => FamilyLink(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    familyMemberId: json['family_member_id'] as String,
    relationship: json['relationship'] as String,
    canViewRecords: json['can_view_records'] as bool? ?? true,
    canViewPrescriptions: json['can_view_prescriptions'] as bool? ?? true,
    canBookConsultations: json['can_book_consultations'] as bool? ?? false,
    canReceiveAlerts: json['can_receive_alerts'] as bool? ?? true,
    status: FamilyLinkStatus.values.firstWhere(
      (e) => e.name == (json['status'] as String),
      orElse: () => FamilyLinkStatus.pending,
    ),
    invitedAt: DateTime.parse(json['invited_at'] as String),
    activatedAt: json['activated_at'] != null
        ? DateTime.parse(json['activated_at'] as String)
        : null,
    revokedAt: json['revoked_at'] != null
        ? DateTime.parse(json['revoked_at'] as String)
        : null,
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
    patientPhone: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['phone'] as String?
        : null,
    familyMemberName: json['family_members'] != null
        ? (json['family_members'] as Map<String, dynamic>)['full_name']
              as String?
        : null,
    familyMemberPhone: json['family_members'] != null
        ? (json['family_members'] as Map<String, dynamic>)['phone'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    familyMemberId,
    relationship,
    canViewRecords,
    canViewPrescriptions,
    canBookConsultations,
    canReceiveAlerts,
    status,
    invitedAt,
    activatedAt,
    revokedAt,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
    patientPhone,
    familyMemberName,
    familyMemberPhone,
  ];
}
