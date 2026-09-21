import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/customer_order.dart';
import '../models/quotation.dart';
import '../models/invoice.dart';
import '../services/sales_service.dart';

class SalesProvider extends ChangeNotifier {
  final SalesService _service = SalesService();

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  List<CustomerOrder> _customerOrders = [];
  CustomerOrder? _selectedCustomerOrder;
  List<Quotation> _quotations = [];
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  List<Supplier> get suppliers => _suppliers;
  Supplier? get selectedSupplier => _selectedSupplier;
  List<CustomerOrder> get customerOrders => _customerOrders;
  CustomerOrder? get selectedCustomerOrder => _selectedCustomerOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCustomers({String? pharmacyId, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _customers = await _service.getCustomers(
        pharmacyId: pharmacyId,
        search: search,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCustomer(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedCustomer = await _service.getCustomer(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveCustomer(Customer customer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      Customer saved;
      if (customer.id.isEmpty || customer.id.startsWith('temp_')) {
        saved = await _service.createCustomer(customer);
        _customers.insert(0, saved);
      } else {
        saved = await _service.updateCustomer(customer);
        final index = _customers.indexWhere((c) => c.id == saved.id);
        if (index != -1) _customers[index] = saved;
      }
      _selectedCustomer = saved;
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

  // ... other methods (suppliers, orders, quotations, invoices)
}
