import 'package:equatable/equatable.dart';

class FinancingRequest extends Equatable {
  final String id;
  final String pharmacyId;
  final String? b2bOrderId;
  final int amount;
  final String? purpose;
  final int repaymentPeriodMonths;
  final double interestRate;
  final String
  status; // pending, approved, rejected, active, completed, defaulted
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? pharmacyName;
  final int? totalRepayments;
  final int? paidRepayments;

  const FinancingRequest({
    required this.id,
    required this.pharmacyId,
    this.b2bOrderId,
    required this.amount,
    this.purpose,
    this.repaymentPeriodMonths = 3,
    this.interestRate = 5.0,
    required this.status,
    this.approvedAt,
    this.disbursedAt,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.pharmacyName,
    this.totalRepayments,
    this.paidRepayments,
  });

  FinancingRequest copyWith({
    String? id,
    String? pharmacyId,
    String? b2bOrderId,
    int? amount,
    String? purpose,
    int? repaymentPeriodMonths,
    double? interestRate,
    String? status,
    DateTime? approvedAt,
    DateTime? disbursedAt,
    DateTime? completedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? pharmacyName,
    int? totalRepayments,
    int? paidRepayments,
  }) {
    return FinancingRequest(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      b2bOrderId: b2bOrderId ?? this.b2bOrderId,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      repaymentPeriodMonths:
          repaymentPeriodMonths ?? this.repaymentPeriodMonths,
      interestRate: interestRate ?? this.interestRate,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      totalRepayments: totalRepayments ?? this.totalRepayments,
      paidRepayments: paidRepayments ?? this.paidRepayments,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pharmacy_id': pharmacyId,
    if (b2bOrderId != null) 'b2b_order_id': b2bOrderId,
    'amount': amount,
    if (purpose != null) 'purpose': purpose,
    'repayment_period_months': repaymentPeriodMonths,
    'interest_rate': interestRate,
    'status': status,
    if (approvedAt != null) 'approved_at': approvedAt!.toIso8601String(),
    if (disbursedAt != null) 'disbursed_at': disbursedAt!.toIso8601String(),
    if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory FinancingRequest.fromJson(Map<String, dynamic> json) =>
      FinancingRequest(
        id: json['id'] as String,
        pharmacyId: json['pharmacy_id'] as String,
        b2bOrderId: json['b2b_order_id'] as String?,
        amount: json['amount'] as int,
        purpose: json['purpose'] as String?,
        repaymentPeriodMonths: json['repayment_period_months'] as int? ?? 3,
        interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 5.0,
        status: json['status'] as String,
        approvedAt: json['approved_at'] != null
            ? DateTime.parse(json['approved_at'] as String)
            : null,
        disbursedAt: json['disbursed_at'] != null
            ? DateTime.parse(json['disbursed_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
        pharmacyName: json['pharmacies'] != null
            ? (json['pharmacies'] as Map<String, dynamic>)['name'] as String?
            : null,
        totalRepayments: json['repayments'] != null
            ? (json['repayments'] as List).length
            : null,
        paidRepayments: json['repayments'] != null
            ? (json['repayments'] as List)
                  .where((e) => e['status'] == 'paid')
                  .length
            : null,
      );

  @override
  List<Object?> get props => [
    id,
    pharmacyId,
    b2bOrderId,
    amount,
    purpose,
    repaymentPeriodMonths,
    interestRate,
    status,
    approvedAt,
    disbursedAt,
    completedAt,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    pharmacyName,
    totalRepayments,
    paidRepayments,
  ];

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      case 'defaulted':
        return 'Défaut';
      default:
        return status;
    }
  }

  String get statusIcon {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      case 'active':
        return '🔄';
      case 'completed':
        return '🏁';
      case 'defaulted':
        return '⚠️';
      default:
        return '📋';
    }
  }

  double get totalRepaymentAmount {
    final total = amount + (amount * interestRate / 100);
    return total;
  }

  double get monthlyPayment {
    final total = totalRepaymentAmount;
    return total / repaymentPeriodMonths;
  }
}
