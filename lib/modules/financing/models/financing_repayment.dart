import 'package:equatable/equatable.dart';

class FinancingRepayment extends Equatable {
  final String id;
  final String financingRequestId;
  final DateTime dueDate;
  final int amount;
  final String status; // pending, paid, overdue, defaulted
  final DateTime? paidAt;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  const FinancingRepayment({
    required this.id,
    required this.financingRequestId,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidAt,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
  });

  FinancingRepayment copyWith({
    String? id,
    String? financingRequestId,
    DateTime? dueDate,
    int? amount,
    String? status,
    DateTime? paidAt,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return FinancingRepayment(
      id: id ?? this.id,
      financingRequestId: financingRequestId ?? this.financingRequestId,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'financing_request_id': financingRequestId,
    'due_date': dueDate.toIso8601String().split('T').first,
    'amount': amount,
    'status': status,
    if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
    if (transactionId != null) 'transaction_id': transactionId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory FinancingRepayment.fromJson(Map<String, dynamic> json) =>
      FinancingRepayment(
        id: json['id'] as String,
        financingRequestId: json['financing_request_id'] as String,
        dueDate: DateTime.parse(json['due_date'] as String),
        amount: json['amount'] as int,
        status: json['status'] as String,
        paidAt: json['paid_at'] != null
            ? DateTime.parse(json['paid_at'] as String)
            : null,
        transactionId: json['transaction_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    financingRequestId,
    dueDate,
    amount,
    status,
    paidAt,
    transactionId,
    createdAt,
    updatedAt,
    gsgId,
    gsgOrgId,
  ];

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'paid':
        return 'Payée';
      case 'overdue':
        return 'En retard';
      case 'defaulted':
        return 'Défaut';
      default:
        return status;
    }
  }

  bool get isOverdue =>
      status == 'overdue' ||
      (status == 'pending' && dueDate.isBefore(DateTime.now()));
}
