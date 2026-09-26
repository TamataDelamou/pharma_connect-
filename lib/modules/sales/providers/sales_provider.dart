import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/customer_order.dart';
import '../models/quotation.dart';
import '../models/sales_invoice.dart';
import '../models/invoice_payment.dart';
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
  Quotation? _selectedQuotation;
  List<SalesInvoice> _salesInvoices = [];
  SalesInvoice? _selectedSalesInvoice;
  List<InvoicePayment> _invoicePayments = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  List<Supplier> get suppliers => _suppliers;
  Supplier? get selectedSupplier => _selectedSupplier;
  List<CustomerOrder> get customerOrders => _customerOrders;
  CustomerOrder? get selectedCustomerOrder => _selectedCustomerOrder;
  List<Quotation> get quotations => _quotations;
  Quotation? get selectedQuotation => _selectedQuotation;
  List<SalesInvoice> get salesInvoices => _salesInvoices;
  SalesInvoice? get selectedSalesInvoice => _selectedSalesInvoice;
  List<InvoicePayment> get invoicePayments => _invoicePayments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---- Customers ----

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

  // ---- Suppliers ----

  Future<void> loadSuppliers({String? pharmacyId, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _suppliers = await _service.getSuppliers(
        pharmacyId: pharmacyId,
        search: search,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSupplier(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedSupplier = await _service.getSupplier(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveSupplier(Supplier supplier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      Supplier saved;
      if (supplier.id.isEmpty || supplier.id.startsWith('temp_')) {
        saved = await _service.createSupplier(supplier);
        _suppliers.insert(0, saved);
      } else {
        saved = await _service.updateSupplier(supplier);
        final index = _suppliers.indexWhere((s) => s.id == saved.id);
        if (index != -1) _suppliers[index] = saved;
      }
      _selectedSupplier = saved;
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

  // ---- Customer Orders ----

  Future<void> loadCustomerOrders({
    String? pharmacyId,
    String? customerId,
    CustomerOrderStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _customerOrders = await _service.getCustomerOrders(
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

  Future<void> loadCustomerOrder(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedCustomerOrder = await _service.getCustomerOrder(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCustomerOrder(CustomerOrder order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createCustomerOrder(order);
      _customerOrders.insert(0, saved);
      _selectedCustomerOrder = saved;
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

  Future<bool> updateCustomerOrder(CustomerOrder order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateCustomerOrder(order);
      final index = _customerOrders.indexWhere((o) => o.id == updated.id);
      if (index != -1) _customerOrders[index] = updated;
      if (_selectedCustomerOrder?.id == updated.id) {
        _selectedCustomerOrder = updated;
      }
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

  Future<bool> deleteCustomerOrder(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteCustomerOrder(id);
      _customerOrders.removeWhere((o) => o.id == id);
      if (_selectedCustomerOrder?.id == id) _selectedCustomerOrder = null;
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

  // ---- Quotations ----

  Future<void> loadQuotations({
    String? pharmacyId,
    String? customerId,
    QuotationStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _quotations = await _service.getQuotations(
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

  Future<void> loadQuotation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedQuotation = await _service.getQuotation(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createQuotation(Quotation quotation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createQuotation(quotation);
      _quotations.insert(0, saved);
      _selectedQuotation = saved;
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

  Future<bool> updateQuotation(Quotation quotation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateQuotation(quotation);
      final index = _quotations.indexWhere((q) => q.id == updated.id);
      if (index != -1) _quotations[index] = updated;
      if (_selectedQuotation?.id == updated.id) _selectedQuotation = updated;
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

  Future<bool> deleteQuotation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteQuotation(id);
      _quotations.removeWhere((q) => q.id == id);
      if (_selectedQuotation?.id == id) _selectedQuotation = null;
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

  // ---- Sales Invoices ----

  Future<void> loadSalesInvoices({
    String? pharmacyId,
    String? customerId,
    SalesInvoiceStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _salesInvoices = await _service.getSalesInvoices(
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

  Future<void> loadSalesInvoice(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedSalesInvoice = await _service.getSalesInvoice(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createSalesInvoice(SalesInvoice invoice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createSalesInvoice(invoice);
      _salesInvoices.insert(0, saved);
      _selectedSalesInvoice = saved;
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

  Future<bool> updateSalesInvoice(SalesInvoice invoice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateSalesInvoice(invoice);
      final index = _salesInvoices.indexWhere((i) => i.id == updated.id);
      if (index != -1) _salesInvoices[index] = updated;
      if (_selectedSalesInvoice?.id == updated.id) {
        _selectedSalesInvoice = updated;
      }
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

  Future<bool> deleteSalesInvoice(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteSalesInvoice(id);
      _salesInvoices.removeWhere((i) => i.id == id);
      if (_selectedSalesInvoice?.id == id) _selectedSalesInvoice = null;
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

  // ---- Invoice Payments ----
  // Le recalcul de paidAmount/status de la facture n'est volontairement pas
  // fait ici : règle métier non tranchée (cf. registre C175).

  Future<void> loadInvoicePayments(String invoiceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _invoicePayments = await _service.getInvoicePayments(invoiceId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createInvoicePayment(InvoicePayment payment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createInvoicePayment(payment);
      _invoicePayments.insert(0, saved);
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

  void clearSelected() {
    _selectedSupplier = null;
    _selectedCustomerOrder = null;
    _selectedQuotation = null;
    _selectedSalesInvoice = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
