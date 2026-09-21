import 'package:equatable/equatable.dart';

class InvoicePayment extends Equatable {
  final String id;
  final String invoiceId;
  final int amount;
  final DateTime paymentDate;
  final String paymentMethod; // cash, mobile_money, card, bank_transfer
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  final String? gsgId;
  final String? gsgOrgId;

  const InvoicePayment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.reference,
    this.notes,
    required this.createdAt,
    this.gsgId,
    this.gsgOrgId,
  });

  InvoicePayment copyWith({
    String? id,
    String? invoiceId,
    int? amount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? reference,
    String? notes,
    DateTime? createdAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return InvoicePayment(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoice_id': invoiceId,
    'amount': amount,
    'payment_date': paymentDate.toIso8601String(),
    'payment_method': paymentMethod,
    if (reference != null) 'reference': reference,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory InvoicePayment.fromJson(Map<String, dynamic> json) =>
      InvoicePayment(
        id: json['id'] as String,
        invoiceId: json['invoice_id'] as String,
        amount: json['amount'] as int,
        paymentDate: DateTime.parse(json['payment_date'] as String),
        paymentMethod: json['payment_method'] as String,
        reference: json['reference'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    invoiceId,
    amount,
    paymentDate,
    paymentMethod,
    reference,
    notes,
    createdAt,
    gsgId,
    gsgOrgId,
  ];
}
