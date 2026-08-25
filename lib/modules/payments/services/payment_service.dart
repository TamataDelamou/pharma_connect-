import 'dart:math';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/payment_method.dart';
import '../models/installment.dart';
import '../models/wallet.dart';
import '../models/invoice.dart';

class PaymentService {
  static final List<Transaction> _transactions = [];
  static final List<Wallet> _wallets = [];
  static final List<Invoice> _invoices = [];
  static final Random _random = Random();

  // Taux
  static const int _feePercent = 1;
  static const int _cashbackPercent = 2;

  // ==================== DONNÉES MOCKÉES ====================

  static final List<Wallet> _mockWallets = [
    Wallet(
      id: 'wal_001',
      userId: 'patient_123',
      balance: 45000,
      pendingBalance: 12000,
      totalEarned: 87000,
      totalSpent: 42000,
      cashbackAvailable: 3400,
      lastUpdated: DateTime(2026, 8, 24),
    ),
  ];

  static final List<Transaction> _mockTransactions = [
    _createMockTransaction(
      id: 'tx_001',
      amount: 15000,
      method: PaymentMethod.orangeMoney,
      status: TransactionStatus.completed,
      pharmacyName: 'Pharmacie Centrale',
    ),
    _createMockTransaction(
      id: 'tx_002',
      amount: 8500,
      method: PaymentMethod.gsgWallet,
      status: TransactionStatus.completed,
      pharmacyName: 'Pharmacie du Soleil',
    ),
    _createMockTransaction(
      id: 'tx_003',
      amount: 35000,
      method: PaymentMethod.mtnMomo,
      status: TransactionStatus.pending,
      pharmacyName: 'Pharmacie Moderne',
    ),
    _createMockTransaction(
      id: 'tx_004',
      amount: 12000,
      method: PaymentMethod.gsgWallet,
      status: TransactionStatus.processing,
      pharmacyName: 'Pharmacie Centrale',
    ),
    _createMockTransaction(
      id: 'tx_005',
      amount: 2800,
      method: PaymentMethod.cashOnDelivery,
      status: TransactionStatus.completed,
      pharmacyName: 'Pharmacie du Soleil',
    ),
    _createMockTransaction(
      id: 'tx_006',
      amount: 7500,
      method: PaymentMethod.orangeMoney,
      status: TransactionStatus.disputed,
      pharmacyName: 'Pharmacie Moderne',
    ),
  ];

  static Transaction _createMockTransaction({
    required String id,
    required int amount,
    required PaymentMethod method,
    required TransactionStatus status,
    required String pharmacyName,
  }) {
    final now = DateTime.now();
    final int fee = (amount * _feePercent) ~/ 100;
    final int cashback = status == TransactionStatus.completed
        ? (amount * _cashbackPercent) ~/ 100
        : 0;
    final int finalAmount = amount + fee - cashback;

    return Transaction(
      id: id,
      userId: 'patient_123',
      userPhone: '+224612345678',
      pharmacyName: pharmacyName,
      amount: amount,
      fee: fee,
      cashback: cashback,
      finalAmount: finalAmount,
      method: method,
      status: status,
      createdAt: now.subtract(Duration(days: _random.nextInt(30))),
      completedAt: status == TransactionStatus.completed
          ? now.subtract(Duration(hours: _random.nextInt(48)))
          : null,
      transactionReference: 'GSG${_random.nextInt(1000000)}',
      externalReference: 'REF${_random.nextInt(10000)}',
      notes: status == TransactionStatus.disputed
          ? 'Paiement non reconnu par le client'
          : null,
    );
  }

  static void _initMockData() {
    if (_transactions.isEmpty) {
      _transactions.addAll(_mockTransactions);
    }
    if (_wallets.isEmpty) {
      _wallets.addAll(_mockWallets);
    }
  }

  // ==================== TRANSACTIONS ====================

  Future<List<Transaction>> getTransactions({
    TransactionStatus? status,
    String? pharmacyId,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMethod? method,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var list = _transactions;

    if (status != null) {
      list = list.where((t) => t.status == status).toList();
    }

    if (pharmacyId != null) {
      list = list.where((t) => t.pharmacyId == pharmacyId).toList();
    }

    if (userId != null) {
      list = list.where((t) => t.userId == userId).toList();
    }

    if (fromDate != null) {
      list = list.where((t) => t.createdAt.isAfter(fromDate)).toList();
    }

    if (toDate != null) {
      list = list.where((t) => t.createdAt.isBefore(toDate)).toList();
    }

    if (method != null) {
      list = list.where((t) => t.method == method).toList();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  }

  Future<Transaction> getTransaction(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _transactions.firstWhere((t) => t.id == id);
  }

  Future<int> getTransactionCount({
    TransactionStatus? status,
    String? userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _initMockData();
    var list = _transactions;
    if (status != null) {
      list = list.where((t) => t.status == status).toList();
    }
    if (userId != null) {
      list = list.where((t) => t.userId == userId).toList();
    }
    return list.length;
  }

  // ==================== PORTEFEUILLE ====================

  Future<Wallet> getWallet(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _wallets.firstWhere((w) => w.userId == userId);
  }

  Future<int> getWalletBalance(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _wallets.firstWhere((w) => w.userId == userId).balance;
  }

  Future<Wallet> topUpWallet({
    required String userId,
    required int amount,
    required PaymentMethod method,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    final index = _wallets.indexWhere((w) => w.userId == userId);
    if (index == -1) throw Exception('Wallet not found');

    final current = _wallets[index];
    final updated = current.copyWith(
      balance: current.balance + amount,
      lastUpdated: DateTime.now(),
    );

    // Ajouter une transaction
    final transaction = Transaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userPhone: '+224612345678',
      amount: amount,
      fee: 0,
      cashback: 0,
      finalAmount: amount,
      method: method,
      status: TransactionStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      transactionReference: 'TOPUP${_random.nextInt(1000000)}',
    );
    _transactions.add(transaction);

    _wallets[index] = updated;
    return updated;
  }

  // ==================== INITIATION ====================

  Future<Transaction> initiateTransaction({
    required String userId,
    required String userPhone,
    required int amount,
    required PaymentMethod method,
    String? reservationId,
    String? deliveryId,
    String? prescriptionId,
    String? pharmacyId,
    String? pharmacyName,
    bool useCashback = false,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    final id = 'tx_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final int fee = method == PaymentMethod.gsgWallet
        ? 0
        : (amount * _feePercent) ~/ 100;
    final int cashback =
        (method.isMobileMoney || method == PaymentMethod.gsgWallet)
        ? (amount * _cashbackPercent) ~/ 100
        : 0;
    final int finalAmount = amount + fee - (useCashback ? cashback : 0);

    final transaction = Transaction(
      id: id,
      userId: userId,
      userPhone: userPhone,
      amount: amount,
      fee: fee,
      cashback: useCashback ? cashback : 0,
      finalAmount: finalAmount,
      method: method,
      status: TransactionStatus.processing,
      createdAt: now,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      reservationId: reservationId,
      deliveryId: deliveryId,
      prescriptionId: prescriptionId,
      transactionReference: 'GSG${_random.nextInt(1000000)}',
    );

    _transactions.add(transaction);

    // Simuler la confirmation
    await Future.delayed(const Duration(seconds: 2));
    final completed = transaction.copyWith(
      status: TransactionStatus.completed,
      completedAt: DateTime.now(),
    );
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) _transactions[index] = completed;

    // Créer une facture
    _createInvoice(completed);

    return completed;
  }

  Future<Transaction> confirmTransaction(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) throw Exception('Transaction not found');

    final updated = _transactions[index].copyWith(
      status: TransactionStatus.completed,
      completedAt: DateTime.now(),
    );
    _transactions[index] = updated;
    _createInvoice(updated);
    return updated;
  }

  Future<Transaction> refundTransaction(
    String transactionId, {
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) throw Exception('Transaction not found');

    final updated = _transactions[index].copyWith(
      status: TransactionStatus.refunded,
      refundedAt: DateTime.now(),
      notes: reason,
    );
    _transactions[index] = updated;
    return updated;
  }

  Future<Transaction> markAsDisputed(
    String transactionId, {
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) throw Exception('Transaction not found');

    final updated = _transactions[index].copyWith(
      status: TransactionStatus.disputed,
      notes: reason,
    );
    _transactions[index] = updated;
    return updated;
  }

  // ==================== ÉCHÉANCIER ====================

  Future<Installment> createInstallment({
    required String transactionId,
    required int totalAmount,
    required int numberOfPayments,
    required DateTime startDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final int amountPerPayment = totalAmount ~/ numberOfPayments;
    final payments = <InstallmentPayment>[];

    for (int i = 0; i < numberOfPayments; i++) {
      final dueDate = startDate.add(Duration(days: (i + 1) * 30));
      payments.add(
        InstallmentPayment(
          number: i + 1,
          amount: amountPerPayment,
          dueDate: dueDate,
          status: i == 0
              ? InstallmentPaymentStatus.pending
              : InstallmentPaymentStatus.pending,
        ),
      );
    }

    return Installment(
      id: 'inst_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: transactionId,
      totalAmount: totalAmount,
      numberOfPayments: numberOfPayments,
      amountPerPayment: amountPerPayment,
      startDate: startDate,
      payments: payments,
      status: InstallmentStatus.active,
    );
  }

  Future<Installment> getInstallment(String installmentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();

    // Simuler un échéancier
    final now = DateTime.now();
    final payments = List.generate(
      3,
      (i) => InstallmentPayment(
        number: i + 1,
        amount: 15000,
        dueDate: now.add(Duration(days: (i + 1) * 30)),
        status: i == 0
            ? InstallmentPaymentStatus.paid
            : i == 1
            ? InstallmentPaymentStatus.pending
            : InstallmentPaymentStatus.pending,
        paidAt: i == 0 ? now.subtract(const Duration(days: 30)) : null,
      ),
    );
    return Installment(
      id: installmentId,
      transactionId: 'tx_${_random.nextInt(1000)}',
      totalAmount: 45000,
      numberOfPayments: 3,
      amountPerPayment: 15000,
      startDate: now.subtract(const Duration(days: 30)),
      payments: payments,
      status: InstallmentStatus.active,
    );
  }

  Future<Installment> payInstallment(
    String installmentId,
    int paymentNumber,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    // Simuler le paiement d'une échéance
    // Dans la réalité, on appellerait une API de paiement
    return getInstallment(installmentId);
  }

  // ==================== FACTURES ====================

  void _createInvoice(Transaction transaction) {
    final invoice = Invoice(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: transaction.id,
      invoiceNumber: 'FAC${_random.nextInt(1000000)}',
      pharmacyName: transaction.pharmacyName ?? 'Pharmacie',
      pharmacyAddress: '123 Rue du Commerce, Conakry',
      pharmacyPhone: '+224622334455',
      patientName: transaction.userId,
      patientAddress: 'Adresse patient',
      patientPhone: transaction.userPhone,
      patientEmail: 'patient@email.com',
      issuedAt: DateTime.now(),
      items: [
        InvoiceItem(
          id: 'item_${_random.nextInt(1000)}',
          productName: 'Médicaments',
          quantity: 1,
          unitPrice: transaction.amount,
          total: transaction.amount,
          dosage: 'N/A',
        ),
      ],
      subtotal: transaction.amount,
      tax: transaction.fee ?? 0,
      discount: transaction.cashback ?? 0,
      total: transaction.finalAmount,
      status: 'paid',
    );
    _invoices.add(invoice);
  }

  Future<Invoice?> getInvoice(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _invoices.firstWhere(
      (i) => i.transactionId == transactionId,
      orElse: () => _invoices.first,
    );
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getPaymentStats(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();

    final userTransactions = _transactions.where((t) => t.userId == userId);
    final completed = userTransactions
        .where((t) => t.status == TransactionStatus.completed)
        .toList();

    return {
      'totalSpent': completed.fold(0, (sum, t) => sum + t.finalAmount),
      'transactionCount': completed.length,
      'averageAmount': completed.isEmpty
          ? 0
          : completed.fold(0, (sum, t) => sum + t.finalAmount) ~/
                completed.length,
      'mostUsedMethod': _getMostUsedMethod(userTransactions.toList()),
      'totalCashback': completed.fold(0, (sum, t) => sum + (t.cashback ?? 0)),
    };
  }

  String _getMostUsedMethod(List<Transaction> transactions) {
    if (transactions.isEmpty) return 'Aucun';
    final counts = <PaymentMethod, int>{};
    for (final t in transactions) {
      counts[t.method] = (counts[t.method] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key.label;
  }
}
