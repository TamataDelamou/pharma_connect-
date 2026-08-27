class Installment {
  final String id;
  final String transactionId;
  final int totalAmount; // unité mineure
  final int numberOfPayments;
  final int amountPerPayment; // unité mineure
  final DateTime startDate;
  final List<InstallmentPayment> payments;
  final InstallmentStatus status;
  final DateTime? completedAt;

  Installment({
    required this.id,
    required this.transactionId,
    required this.totalAmount,
    required this.numberOfPayments,
    required this.amountPerPayment,
    required this.startDate,
    required this.payments,
    required this.status,
    this.completedAt,
  });

  factory Installment.fromJson(Map<String, dynamic> json) => Installment(
    id: json['id'] as String,
    transactionId: json['transaction_id'] as String,
    totalAmount: json['total_amount'] as int,
    numberOfPayments: json['number_of_payments'] as int,
    amountPerPayment: json['amount_per_payment'] as int,
    startDate: DateTime.parse(json['start_date'] as String),
    payments:
        (json['installment_payments'] as List<dynamic>? ?? [])
            .map(
              (p) => InstallmentPayment.fromJson(p as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) => a.number.compareTo(b.number)),
    status: InstallmentStatus.values.byName(json['status'] as String),
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String)
        : null,
  );

  // payments n'est jamais écrit ici : installment_payments est une table
  // séparée, insérée/mise à jour indépendamment par PaymentService.
  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction_id': transactionId,
    'total_amount': totalAmount,
    'number_of_payments': numberOfPayments,
    'amount_per_payment': amountPerPayment,
    'start_date': startDate.toIso8601String(),
    'status': status.name,
    'completed_at': completedAt?.toIso8601String(),
  };

  int get remainingAmount {
    final totalPaid = payments.fold(
      0,
      (sum, p) =>
          p.status == InstallmentPaymentStatus.paid ? sum + p.amount : sum,
    );
    return totalAmount - totalPaid;
  }

  int get paidCount =>
      payments.where((p) => p.status == InstallmentPaymentStatus.paid).length;
  int get pendingCount => payments
      .where((p) => p.status == InstallmentPaymentStatus.pending)
      .length;

  bool get isComplete => status == InstallmentStatus.completed;
  bool get isActive => status == InstallmentStatus.active;
  bool get isDelayed => status == InstallmentStatus.delayed;
}

class InstallmentPayment {
  final int number;
  final int amount; // unité mineure
  final DateTime dueDate;
  final DateTime? paidAt;
  final InstallmentPaymentStatus status;
  final String? transactionReference;

  InstallmentPayment({
    required this.number,
    required this.amount,
    required this.dueDate,
    this.paidAt,
    required this.status,
    this.transactionReference,
  });

  factory InstallmentPayment.fromJson(Map<String, dynamic> json) =>
      InstallmentPayment(
        number: json['payment_number'] as int,
        amount: json['amount'] as int,
        dueDate: DateTime.parse(json['due_date'] as String),
        paidAt: json['paid_at'] != null
            ? DateTime.parse(json['paid_at'] as String)
            : null,
        status: InstallmentPaymentStatus.values.byName(
          json['status'] as String,
        ),
        transactionReference: json['transaction_reference'] as String?,
      );

  Map<String, dynamic> toJson({required String installmentId}) => {
    'installment_id': installmentId,
    'payment_number': number,
    'amount': amount,
    'due_date': dueDate.toIso8601String(),
    'paid_at': paidAt?.toIso8601String(),
    'status': status.name,
    'transaction_reference': transactionReference,
  };

  InstallmentPayment copyWith({
    int? number,
    int? amount,
    DateTime? dueDate,
    DateTime? paidAt,
    InstallmentPaymentStatus? status,
    String? transactionReference,
  }) {
    return InstallmentPayment(
      number: number ?? this.number,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      status: status ?? this.status,
      transactionReference: transactionReference ?? this.transactionReference,
    );
  }

  String get statusLabel {
    switch (status) {
      case InstallmentPaymentStatus.pending:
        return 'En attente';
      case InstallmentPaymentStatus.paid:
        return 'Payée';
      case InstallmentPaymentStatus.late:
        return 'En retard';
      case InstallmentPaymentStatus.cancelled:
        return 'Annulée';
    }
  }
}

enum InstallmentStatus { active, completed, delayed, cancelled }

enum InstallmentPaymentStatus { pending, paid, late, cancelled }
