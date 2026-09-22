import 'package:equatable/equatable.dart';

class ReimbursementTracking extends Equatable {
  final String id;
  final String claimId;
  final String
  status; // submitted, under_review, approved, reimbursed, rejected
  final int? submittedAmount;
  final int? approvedAmount;
  final int? reimbursedAmount;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? reimbursedAt;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const ReimbursementTracking({
    required this.id,
    required this.claimId,
    required this.status,
    this.submittedAmount,
    this.approvedAmount,
    this.reimbursedAmount,
    this.submittedAt,
    this.reviewedAt,
    this.reimbursedAt,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  ReimbursementTracking copyWith({
    String? id,
    String? claimId,
    String? status,
    int? submittedAmount,
    int? approvedAmount,
    int? reimbursedAmount,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? reimbursedAt,
    String? rejectionReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return ReimbursementTracking(
      id: id ?? this.id,
      claimId: claimId ?? this.claimId,
      status: status ?? this.status,
      submittedAmount: submittedAmount ?? this.submittedAmount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      reimbursedAmount: reimbursedAmount ?? this.reimbursedAmount,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reimbursedAt: reimbursedAt ?? this.reimbursedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
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
    'claim_id': claimId,
    'status': status,
    if (submittedAmount != null) 'submitted_amount': submittedAmount,
    if (approvedAmount != null) 'approved_amount': approvedAmount,
    if (reimbursedAmount != null) 'reimbursed_amount': reimbursedAmount,
    if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
    if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
    if (reimbursedAt != null) 'reimbursed_at': reimbursedAt!.toIso8601String(),
    if (rejectionReason != null) 'rejection_reason': rejectionReason,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory ReimbursementTracking.fromJson(Map<String, dynamic> json) =>
      ReimbursementTracking(
        id: json['id'] as String,
        claimId: json['claim_id'] as String,
        status: json['status'] as String,
        submittedAmount: json['submitted_amount'] as int?,
        approvedAmount: json['approved_amount'] as int?,
        reimbursedAmount: json['reimbursed_amount'] as int?,
        submittedAt: json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'] as String)
            : null,
        reviewedAt: json['reviewed_at'] != null
            ? DateTime.parse(json['reviewed_at'] as String)
            : null,
        reimbursedAt: json['reimbursed_at'] != null
            ? DateTime.parse(json['reimbursed_at'] as String)
            : null,
        rejectionReason: json['rejection_reason'] as String?,
        notes: json['notes'] as String?,
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
    claimId,
    status,
    submittedAmount,
    approvedAmount,
    reimbursedAmount,
    submittedAt,
    reviewedAt,
    reimbursedAt,
    rejectionReason,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return '📤 Soumis';
      case 'under_review':
        return '🔍 En cours d\'examen';
      case 'approved':
        return '✅ Approuvé';
      case 'reimbursed':
        return '💰 Remboursé';
      case 'rejected':
        return '❌ Rejeté';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'submitted':
        return '#F59E0B';
      case 'under_review':
        return '#00D9FF';
      case 'approved':
        return '#10B981';
      case 'reimbursed':
        return '#10B981';
      case 'rejected':
        return '#EF4444';
      default:
        return '#9CA3AF';
    }
  }

  bool get isCompleted => status == 'reimbursed' || status == 'rejected';
  bool get isApproved => status == 'approved' || status == 'reimbursed';
}
