import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/payment_method.dart';
import '../models/installment.dart';
import '../models/wallet.dart';
import '../models/invoice.dart';
import '../services/payment_service.dart';
import '../../../core/services/offline_sync_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();
  final OfflineSyncService _offlineSync = OfflineSyncService();

  List<Transaction> _transactions = [];
  Transaction? _selectedTransaction;
  Installment? _currentInstallment;
  Wallet? _wallet;
  Invoice? _currentInvoice;
  int _walletBalance = 0;
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;

  // Getters
  List<Transaction> get transactions => _transactions;
  Transaction? get selectedTransaction => _selectedTransaction;
  Installment? get currentInstallment => _currentInstallment;
  Wallet? get wallet => _wallet;
  Invoice? get currentInvoice => _currentInvoice;
  int get walletBalance => _walletBalance;
  bool get isLoading => _isLoading;
  // Directive standing « privilégier le mode hors-ligne » (audit Module 8,
  // 29/08/2026) : appliquée ici seulement à la LECTURE (solde, historique).
  // Voir offline_sync_service.dart pour la justification de ne PAS étendre
  // ce repli aux écritures (initiation de paiement, recharge, échéance) —
  // risque de double débit/double confirmation au rejeu.
  bool get isOffline => _isOffline;
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

  // Directive standing « privilégier le mode hors-ligne » (audit Module 8,
  // 29/08/2026), lecture seule — même patron que
  // DeliveryProvider.loadDeliveriesForPatient (Module 7). La clé de cache
  // reste userId : les vues filtrées par statut/pharmacie ne bénéficient
  // pas du repli (cas d'usage back-office, pas prioritaire hors-ligne).
  Future<void> loadTransactions({
    TransactionStatus? status,
    String? userId,
    String? pharmacyId,
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
        pharmacyId: pharmacyId,
        fromDate: fromDate,
        toDate: toDate,
      );
      _isOffline = false;
      if (userId != null) {
        unawaited(
          _offlineSync.cacheTransactions(
            userId,
            _transactions.map((t) => t.toJson()).toList(),
          ),
        );
      }
    } catch (e) {
      final cached = userId != null
          ? await _offlineSync.getCachedTransactions(userId)
          : <Map<String, dynamic>>[];
      if (cached.isNotEmpty) {
        _transactions = cached.map((row) => Transaction.fromJson(row)).toList();
        _isOffline = true;
        _error =
            'Hors connexion — dernières transactions synchronisées affichées (${_transactions.length}).';
      } else {
        _error = e.toString();
      }
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

  // Bug corrigé (audit Module 8, 29/08/2026) : appelait service.getWallet
  // (.single(), lève une exception si aucune ligne n'existe) — remplacé par
  // getOrCreateWallet, qui auto-provisionne. Repli hors-ligne (lecture
  // seule) ajouté, même patron que loadTransactions ci-dessus.
  Future<void> loadWallet(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallet = await _service.getOrCreateWallet(userId);
      _walletBalance = _wallet?.balance ?? 0;
      _isOffline = false;
      unawaited(_offlineSync.cacheWallet(userId, _wallet!.toJson()));
    } catch (e) {
      final cached = await _offlineSync.getCachedWallet(userId);
      if (cached != null) {
        _wallet = Wallet.fromJson(cached);
        _walletBalance = _wallet?.balance ?? 0;
        _isOffline = true;
        _error = 'Hors connexion — dernier solde synchronisé affiché.';
      } else {
        _error = e.toString();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Bug corrigé (audit Module 8, 29/08/2026) : loadInstallment(id) passait
  // un id de TRANSACTION (voir installment_plan_screen.dart) à
  // service.getInstallment(installmentId), qui cherchait par
  // installments.id — jamais de correspondance. Signature inchangée
  // (aucune modification requise côté écran) ; résolution corrigée en
  // interne via getInstallmentByTransaction.
  Future<void> loadInstallment(String transactionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentInstallment = await _service.getInstallmentByTransaction(
        transactionId,
      );
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
    // Bug corrigé (audit Module 8, 29/08/2026) : PaymentService.createInstallment
    // existait déjà, complet et correct, mais n'avait aucun appelant nulle
    // part dans le module — "Paiement en plusieurs fois" ne créait jamais
    // d'échéancier. numberOfPayments n'est utilisé que pour
    // PaymentMethod.installment (3 par défaut).
    int numberOfPayments = 3,
  }) async {
    // C239 : aucun paiement par un moyen masqué pour le pilote, quel que
    // soit l'écran appelant.
    if (!method.isEnabled) {
      _error = 'Ce moyen de paiement n\'est pas disponible.';
      notifyListeners();
      return null;
    }
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
      if (method == PaymentMethod.installment) {
        _currentInstallment = await _service.createInstallment(
          transactionId: transaction.id,
          totalAmount: transaction.finalAmount,
          numberOfPayments: numberOfPayments,
          startDate: DateTime.now(),
        );
      }
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

  // Signature inchangée (installment_plan_screen.dart transmet en réalité
  // widget.transactionId, voir loadInstallment ci-dessus) — résolution
  // corrigée en interne via payInstallmentByTransaction.
  Future<bool> payInstallment(String transactionId, int paymentNumber) async {
    try {
      final updated = await _service.payInstallmentByTransaction(
        transactionId,
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
