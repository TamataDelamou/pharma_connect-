import 'package:flutter/material.dart';
import '../models/customer_return.dart';
import '../models/customer_return_item.dart';
import '../models/supplier_return.dart';
import '../models/return_reason.dart';
import '../services/returns_service.dart';

class ReturnsProvider extends ChangeNotifier {
  final ReturnsService _service = ReturnsService();

  List<CustomerReturn> _customerReturns = [];
  CustomerReturn? _selectedCustomerReturn;
  List<SupplierReturn> _supplierReturns = [];
  SupplierReturn? _selectedSupplierReturn;
  List<ReturnReason> _reasons = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerReturn> get customerReturns => _customerReturns;
  CustomerReturn? get selectedCustomerReturn => _selectedCustomerReturn;
  List<SupplierReturn> get supplierReturns => _supplierReturns;
  SupplierReturn? get selectedSupplierReturn => _selectedSupplierReturn;
  List<ReturnReason> get reasons => _reasons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCustomerReturns({
    String? pharmacyId,
    String? customerId,
    ReturnStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _customerReturns = await _service.getCustomerReturns(
        pharmacyId: pharmacyId,
        customerId: customerId,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCustomerReturn(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedCustomerReturn = await _service.getCustomerReturn(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCustomerReturn(CustomerReturn returnData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createCustomerReturn(returnData);
      _customerReturns.insert(0, saved);
      _selectedCustomerReturn = saved;
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

  Future<bool> updateCustomerReturnStatus(
    String id,
    ReturnStatus status, {
    int? refundAmount,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateCustomerReturnStatus(
        id,
        status,
        refundAmount: refundAmount,
        notes: notes,
      );
      final index = _customerReturns.indexWhere((r) => r.id == updated.id);
      if (index != -1) _customerReturns[index] = updated;
      if (_selectedCustomerReturn?.id == updated.id)
        _selectedCustomerReturn = updated;
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

  Future<void> loadReasons({String? category}) async {
    try {
      _reasons = await _service.getReturnReasons(category: category);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  void clearSelected() {
    _selectedCustomerReturn = null;
    _selectedSupplierReturn = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
