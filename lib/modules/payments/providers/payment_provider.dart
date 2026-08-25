import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/payment_method.dart';
import '../models/installment.dart';
import '../models/wallet.dart';
import '../models/invoice.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  List<Transaction> _transactions = [];
  Transaction? _selectedTransaction;
  Installment? _currentInstallment;
  Wallet? _wallet;
  Invoice? _currentInvoice;
  int _walletBalance = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Transaction> get transactions => _transactions;
  Transaction? get selectedTransaction => _selectedTransaction;
  Installment? get currentInstallment => _currentInstallment;
  Wallet? get wallet => _wallet;
  Invoice? get currentInvoice => _currentInvoice;
  int get walletBalance => _walletBalance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Transaction> get completedTransactions {
    return _transactions
        .where((t) => t.status == TransactionStatus.completed)
        .toList();
  }

  List<Transaction> get pendingTransactions {
    return _transactions
        .where((t) => t.status == TransactionStatus.pending)
        .toList();
  }

  List<Transaction> get disputedTransactions {
    return _transactions
        .where((t) => t.status == TransactionStatus.disputed)
        .toList();
  }

  // ==================== LOAD ====================

  Future<void> loadTransactions({
    TransactionStatus? status,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _service.getTransactions(
        status: status,
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTransaction(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTransaction = await _service.getTransaction(id);
      _currentInvoice = await _service.getInvoice(id);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadWallet(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallet = await _service.getWallet(userId);
      _walletBalance = _wallet?.balance ?? 0;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadInstallment(String installmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentInstallment = await _service.getInstallment(installmentId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== PAIEMENT ====================

  Future<Transaction?> initiatePayment({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final transaction = await _service.initiateTransaction(
        userId: userId,
        userPhone: userPhone,
        amount: amount,
        method: method,
        reservationId: reservationId,
        deliveryId: deliveryId,
        prescriptionId: prescriptionId,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
        useCashback: useCashback,
      );
      _transactions.add(transaction);
      _isLoading = false;
      notifyListeners();
      return transaction;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmPayment(String transactionId) async {
    try {
      final updated = await _service.confirmTransaction(transactionId);
      _updateTransaction(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> refundPayment(String transactionId, {String? reason}) async {
    try {
      final updated = await _service.refundTransaction(
        transactionId,
        reason: reason,
      );
      _updateTransaction(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsDisputed(String transactionId, {String? reason}) async {
    try {
      final updated = await _service.markAsDisputed(
        transactionId,
        reason: reason,
      );
      _updateTransaction(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== PORTEFEUILLE ====================

  Future<bool> topUpWallet({
    required String userId,
    required int amount,
    required PaymentMethod method,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.topUpWallet(
        userId: userId,
        amount: amount,
        method: method,
      );
      _wallet = updated;
      _walletBalance = updated.balance;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== ÉCHÉANCIER ====================

  Future<Installment?> createInstallment({
    required String transactionId,
    required int totalAmount,
    required int numberOfPayments,
    required DateTime startDate,
  }) async {
    try {
      final installment = await _service.createInstallment(
        transactionId: transactionId,
        totalAmount: totalAmount,
        numberOfPayments: numberOfPayments,
        startDate: startDate,
      );
      _currentInstallment = installment;
      notifyListeners();
      return installment;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> payInstallment(String installmentId, int paymentNumber) async {
    try {
      final updated = await _service.payInstallment(
        installmentId,
        paymentNumber,
      );
      _currentInstallment = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== UTILITAIRES ====================

  void _updateTransaction(Transaction updated) {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) _transactions[index] = updated;
    if (_selectedTransaction?.id == updated.id) _selectedTransaction = updated;
    notifyListeners();
  }

  void clearSelected() {
    _selectedTransaction = null;
    _currentInvoice = null;
    _currentInstallment = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
