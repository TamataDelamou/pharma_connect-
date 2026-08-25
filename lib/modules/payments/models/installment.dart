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
