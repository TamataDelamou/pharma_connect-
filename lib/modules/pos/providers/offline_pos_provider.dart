import 'package:flutter/material.dart';
import 'package:pharma_connect/core/services/offline_sales_service.dart';
import '../models/pos_sale.dart';
import '../models/pos_sale_item.dart';

class OfflinePOSProvider extends ChangeNotifier {
  final OfflineSalesService _offlineService = OfflineSalesService();

  bool _isOffline = false;
  bool _isSyncing = false;
  int _pendingSales = 0;
  String? _error;

  bool get isOffline => _isOffline;
  bool get isSyncing => _isSyncing;
  int get pendingSales => _pendingSales;
  String? get error => _error;

  Future<void> checkConnectivity() async {
    _isOffline = !(await _offlineService.hasInternet());
    notifyListeners();
  }

  Future<void> loadPendingSales() async {
    try {
      final sales = await _offlineService.getOfflineSales();
      _pendingSales = sales.length;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> saveSaleOffline({
    required String pharmacyId,
    required String cashierId,
    required POSSale sale,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await _offlineService.saveOfflineSale(
        pharmacyId: pharmacyId,
        cashierId: cashierId,
        sale: sale,
        items: items,
      );
      await loadPendingSales();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> syncSales() async {
    if (await _offlineService.hasInternet()) {
      _isSyncing = true;
      notifyListeners();
      try {
        await _offlineService.syncOfflineSales();
        await loadPendingSales();
      } catch (e) {
        _error = e.toString();
      }
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(
    String pharmacyId,
    String query,
  ) async {
    try {
      return await _offlineService.searchProducts(pharmacyId, query);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  Future<void> cacheProducts(
    String pharmacyId,
    List<Map<String, dynamic>> products,
  ) async {
    try {
      await _offlineService.cacheProducts(pharmacyId, products);
    } catch (e) {
      _error = e.toString();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
