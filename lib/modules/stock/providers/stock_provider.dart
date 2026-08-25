import 'package:flutter/material.dart';
import '../../../shared/models/product.dart';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import '../models/stock_batch.dart';
import '../models/stock_status.dart';
import '../models/stock_adjustment.dart';
import '../services/stock_service.dart';

class StockProvider extends ChangeNotifier {
  final StockService _service = StockService();

  List<StockItem> _stockItems = [];
  StockItem? _selectedStockItem;
  List<StockMovement> _movements = [];
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;
  String? _selectedProductId;

  // Getters
  List<StockItem> get stockItems => _stockItems;
  StockItem? get selectedStockItem => _selectedStockItem;
  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;

  // ==================== CHARGEMENT ====================

  Future<void> loadStock({String? productId, String? searchQuery}) async {
    _isLoading = true;
    _error = null;
    _selectedProductId = productId;
    _searchQuery = searchQuery;
    notifyListeners();

    try {
      var items = await _service.getStockItems(productId: productId);

      // Filtre par recherche textuelle
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lower = searchQuery.toLowerCase();
        items = items
            .where(
              (item) =>
                  item.product.name.toLowerCase().contains(lower) ||
                  item.product.genericName.toLowerCase().contains(lower) ||
                  item.product.manufacturer.toLowerCase().contains(lower),
            )
            .toList();
      }

      _stockItems = items;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStockItem(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedStockItem = await _service.getStockItem(id);
      if (_selectedStockItem != null) {
        _movements = await _service.getMovements(stockItemId: id);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMovements({String? stockItemId, String? batchId}) async {
    try {
      _movements = await _service.getMovements(
        stockItemId: stockItemId,
        batchId: batchId,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== ACTIONS ====================

  Future<bool> reserveStock({
    required String productId,
    required int quantity,
    String? referenceId,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.reserveStock(
        productId: productId,
        quantity: quantity,
        referenceId: referenceId,
        userId: userId,
      );
      _isLoading = false;
      notifyListeners();
      // Recharger pour mettre à jour l'UI
      await loadStock(productId: _selectedProductId, searchQuery: _searchQuery);
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmReservation({
    required String productId,
    required int quantity,
    String? referenceId,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.confirmReservation(
        productId: productId,
        quantity: quantity,
        referenceId: referenceId,
        userId: userId,
      );
      _isLoading = false;
      notifyListeners();
      await loadStock(productId: _selectedProductId, searchQuery: _searchQuery);
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelReservation({
    required String productId,
    required int quantity,
    String? referenceId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.cancelReservation(
        productId: productId,
        quantity: quantity,
        referenceId: referenceId,
      );
      _isLoading = false;
      notifyListeners();
      await loadStock(productId: _selectedProductId, searchQuery: _searchQuery);
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== FILTRES ====================

  void search(String query) {
    loadStock(productId: _selectedProductId, searchQuery: query);
  }

  void clearFilters() {
    _selectedProductId = null;
    _searchQuery = null;
    loadStock();
  }

  void clearSelected() {
    _selectedStockItem = null;
    _movements = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Ajouter ces getters et méthodes

  List<StockItem> get lowStockItems =>
      _stockItems.where((item) => item.isLowStock).toList();
  List<StockItem> get criticalStockItems =>
      _stockItems.where((item) => item.isCriticalStock).toList();
  List<StockItem> get outOfStockItems =>
      _stockItems.where((item) => item.isOutOfStock).toList();

  Future<void> loadAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = await _service.getStockItems();
      _stockItems = items;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> adjustStock({
    required String productId,
    required int quantity,
    required AdjustmentReason reason,
    String? batchId,
    String? userId,
    String? userName,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.adjustStock(
        productId: productId,
        quantity: quantity,
        reason: reason,
        batchId: batchId,
        userId: userId,
        userName: userName,
        notes: notes,
      );
      _isLoading = false;
      notifyListeners();
      await loadStock();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> transferStock({
    required String productId,
    required int quantity,
    required String fromPharmacyId,
    required String toPharmacyId,
    String? userId,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.transferStock(
        productId: productId,
        quantity: quantity,
        fromPharmacyId: fromPharmacyId,
        toPharmacyId: toPharmacyId,
        userId: userId,
        notes: notes,
      );
      _isLoading = false;
      notifyListeners();
      await loadStock();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<StockBatch>> getExpiringBatches({int daysThreshold = 30}) async {
    try {
      return await _service.getExpiringBatches(daysThreshold: daysThreshold);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> advancedSearch({
    String? query,
    String? batchNumber,
    String? supplierId,
    DateTime? expiryBefore,
    DateTime? expiryAfter,
    StockStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stockItems = await _service.searchStock(
        query: query,
        batchNumber: batchNumber,
        supplierId: supplierId,
        expiryBefore: expiryBefore,
        expiryAfter: expiryAfter,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
