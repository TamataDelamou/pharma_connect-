import 'package:flutter/material.dart';
import 'package:pharma_connect/core/utils/user_message.dart';
import '../models/pos_sale.dart';
import '../models/pos_sale_item.dart';
import '../models/pos_receipt.dart';
import '../services/pos_service.dart';

class POSProvider extends ChangeNotifier {
  final POSService _service;

  /// [service] : remplaçable dans les tests.
  POSProvider({POSService? service}) : _service = service ?? POSService();

  List<POSSale> _sales = [];
  List<POSSaleItem> _cart = [];
  POSSale? _currentSale;
  POSReceipt? _currentReceipt;
  bool _isLoading = false;
  bool _isCheckingOut = false;
  bool _isPrinting = false;
  String? _error;
  String _selectedPaymentMethod = 'cash';
  List<POSSale> _refunds = [];
  bool _isLoadingRefunds = false;
  String? _refundsError;

  List<POSSale> get sales => _sales;
  List<POSSaleItem> get cart => _cart;
  POSSale? get currentSale => _currentSale;
  POSReceipt? get currentReceipt => _currentReceipt;
  bool get isLoading => _isLoading;
  bool get isCheckingOut => _isCheckingOut;
  bool get isPrinting => _isPrinting;
  String? get error => _error;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  List<POSSale> get refunds => _refunds;
  bool get isLoadingRefunds => _isLoadingRefunds;
  String? get refundsError => _refundsError;

  double get total {
    return _cart.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // C262 : plus de remise au comptoir. La réglette de l'écran de vente était
  // déplacée par erreur et rien ne plafonnait la remise ; le serveur refuse
  // désormais toute vente avec une remise non nulle. La remise exceptionnelle
  // validée par un responsable est une évolution à part (FEAT-005).

  double get taxAmount {
    return total * 0.05; // 5% TVA
  }

  double get finalTotal {
    return total + taxAmount;
  }

  // ---- Cart Management ----

  void addToCart(POSSaleItem item) {
    final existingIndex = _cart.indexWhere(
      (i) => i.productId == item.productId,
    );
    if (existingIndex != -1) {
      final existing = _cart[existingIndex];
      _cart[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
        totalPrice: (existing.quantity + item.quantity) * existing.unitPrice,
      );
    } else {
      _cart.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateCartItemQuantity(String productId, int quantity) {
    final index = _cart.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        final item = _cart[index];
        _cart[index] = item.copyWith(
          quantity: quantity,
          totalPrice: quantity * item.unitPrice,
        );
      }
      notifyListeners();
    }
  }

  /// Quantité déjà dans le panier pour un produit (plafond de l'ajout).
  int quantityInCart(String productId) => _cart
      .where((i) => i.productId == productId)
      .fold(0, (sum, i) => sum + i.quantity);

  /// C201 / D60 : confirmation « ordonnance vue » pour un produit du panier.
  void setPrescriptionChecked(String productId, bool checked) {
    final index = _cart.indexWhere((item) => item.productId == productId);
    if (index == -1) return;
    _cart[index] = _cart[index].copyWith(prescriptionChecked: checked);
    notifyListeners();
  }

  /// Confirme l'ordonnance pour toutes les lignes sur ordonnance du panier.
  void checkAllPrescriptions() {
    for (var i = 0; i < _cart.length; i++) {
      if (_cart[i].prescriptionRequired) {
        _cart[i] = _cart[i].copyWith(prescriptionChecked: true);
      }
    }
    notifyListeners();
  }

  /// Lignes sur ordonnance dont l'ordonnance n'a pas été confirmée.
  List<POSSaleItem> get uncheckedPrescriptionItems => _cart
      .where((i) => i.prescriptionRequired && !i.prescriptionChecked)
      .toList();

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  // ---- Checkout ----

  Future<bool> checkout({
    required String pharmacyId,
    required String cashierId,
    String? patientId,
  }) async {
    if (_cart.isEmpty) return false;

    _isCheckingOut = true;
    _error = null;
    notifyListeners();

    try {
      final sale = POSSale(
        id: '',
        pharmacyId: pharmacyId,
        saleNumber: '',
        patientId: patientId,
        cashierId: cashierId,
        totalAmount: total.round(),
        discountAmount: 0,
        taxAmount: taxAmount.round(),
        finalAmount: finalTotal.round(),
        paymentMethod: _selectedPaymentMethod,
        status: 'completed',
        items: _cart,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      _currentSale = await _service.createSale(sale);
      _currentReceipt = await _service.getReceipt(_currentSale!.id);
      _cart.clear();
      _isCheckingOut = false;
      notifyListeners();
      return true;
    } on POSSaleException catch (e) {
      _error = e.message;
      _isCheckingOut = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = userMessage(e);
      _isCheckingOut = false;
      notifyListeners();
      return false;
    }
  }

  // ---- Sales History ----

  Future<void> loadSales({
    String? pharmacyId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _sales = await _service.getSales(
        pharmacyId: pharmacyId,
        status: status,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _error = userMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSale(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentSale = await _service.getSale(id);
      if (_currentSale != null) {
        _currentReceipt = await _service.getReceipt(id);
      }
    } catch (e) {
      _error = userMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  /// C204 : motif et destination du stock obligatoires ; la règle (jour
  /// même, plafond, titulaire) est appliquée par le serveur. En cas de refus,
  /// [error] porte le message du serveur, lisible tel quel.
  Future<bool> refundSale(
    String saleId, {
    required String reason,
    required String stockDisposition,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentSale = await _service.refundSale(
        saleId,
        reason: reason,
        stockDisposition: stockDisposition,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on POSRefundException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// C204 : liste des remboursements de la période (rapports POS).
  Future<void> loadRefunds({
    required String pharmacyId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    _isLoadingRefunds = true;
    _refundsError = null;
    notifyListeners();
    try {
      _refunds = await _service.getRefunds(
        pharmacyId: pharmacyId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _refundsError = userMessage(e);
    }
    _isLoadingRefunds = false;
    notifyListeners();
  }

  Future<bool> printReceipt() async {
    if (_currentSale == null) return false;

    _isPrinting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.generateReceiptPDF(_currentSale!.id);
      _currentReceipt = await _service.getReceipt(_currentSale!.id);
      _isPrinting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = userMessage(e);
      _isPrinting = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrent() {
    _currentSale = null;
    _currentReceipt = null;
    notifyListeners();
  }
}
