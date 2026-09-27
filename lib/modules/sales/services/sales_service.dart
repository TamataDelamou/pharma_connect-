import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/customer_order.dart';
import '../models/customer_order_item.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../models/sales_invoice.dart';
import '../models/invoice_payment.dart';

class SalesService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Customers ----

  Future<List<Customer>> getCustomers({
    String? pharmacyId,
    String? search,
    bool? isActive,
  }) async {
    try {
      var query = _client
          .from('customers')
          .select();

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or(
          'first_name.ilike.%$search%,'
          'last_name.ilike.%$search%,'
          'code.ilike.%$search%,'
          'phone.ilike.%$search%',
        );
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  Future<Customer?> getCustomer(String id) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Customer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load customer: $e');
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = customer
          .copyWith(
            id: id,
            isActive: true,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('customers')
          .insert(data)
          .select()
          .single();
      return Customer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final data = customer
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('customers')
          .update(data)
          .eq('id', customer.id)
          .select()
          .single();
      return Customer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _client.from('customers').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  // ---- Suppliers ----

  Future<List<Supplier>> getSuppliers({
    String? pharmacyId,
    String? search,
    bool? isActive,
  }) async {
    try {
      var query = _client
          .from('suppliers')
          .select();

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or(
          'name.ilike.%$search%,'
          'code.ilike.%$search%,'
          'contact_person.ilike.%$search%',
        );
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load suppliers: $e');
    }
  }

  Future<Supplier?> getSupplier(String id) async {
    try {
      final response = await _client
          .from('suppliers')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Supplier.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load supplier: $e');
    }
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = supplier
          .copyWith(
            id: id,
            isActive: true,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('suppliers')
          .insert(data)
          .select()
          .single();
      return Supplier.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create supplier: $e');
    }
  }

  Future<Supplier> updateSupplier(Supplier supplier) async {
    try {
      final data = supplier
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('suppliers')
          .update(data)
          .eq('id', supplier.id)
          .select()
          .single();
      return Supplier.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update supplier: $e');
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _client.from('suppliers').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete supplier: $e');
    }
  }

  // ---- Customer Orders ----

  Future<List<CustomerOrder>> getCustomerOrders({
    String? pharmacyId,
    String? customerId,
    CustomerOrderStatus? status,
  }) async {
    try {
      var query = _client
          .from('customer_orders')
          .select('*, customers:customer_id(first_name, last_name)');

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query.order('order_date', ascending: false);
      return (response as List)
          .map((e) => CustomerOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load customer orders: $e');
    }
  }

  Future<CustomerOrder?> getCustomerOrder(String id) async {
    try {
      final response = await _client
          .from('customer_orders')
          .select('*, customers:customer_id(first_name, last_name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return CustomerOrder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load customer order: $e');
    }
  }

  Future<CustomerOrder> createCustomerOrder(CustomerOrder order) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = order
          .copyWith(
            id: id,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere((key, value) => key == 'items' || key == 'customer_name');

      final response = await _client
          .from('customer_orders')
          .insert(data)
          .select()
          .single();

      if (order.items != null) {
        for (final item in order.items!) {
          await _createCustomerOrderItem(id, item);
        }
      }

      return CustomerOrder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create customer order: $e');
    }
  }

  Future<void> _createCustomerOrderItem(
    String orderId,
    CustomerOrderItem item,
  ) async {
    final itemData = item
        .copyWith(id: _uuid.v4(), orderId: orderId, createdAt: DateTime.now().toUtc())
        .toJson();
    await _client.from('customer_order_items').insert(itemData);
  }

  Future<CustomerOrder> updateCustomerOrder(CustomerOrder order) async {
    try {
      final data = order
          .copyWith(updatedAt: DateTime.now().toUtc(), updatedBy: SupabaseService().currentUser?.id)
          .toJson();
      data.removeWhere((key, value) => key == 'items' || key == 'customer_name');
      final response = await _client
          .from('customer_orders')
          .update(data)
          .eq('id', order.id)
          .select()
          .single();
      return CustomerOrder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update customer order: $e');
    }
  }

  Future<void> deleteCustomerOrder(String id) async {
    try {
      await _client.from('customer_orders').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete customer order: $e');
    }
  }

  // ---- Quotations ----

  Future<List<Quotation>> getQuotations({
    String? pharmacyId,
    String? customerId,
    QuotationStatus? status,
  }) async {
    try {
      var query = _client
          .from('quotations')
          .select('*, customers:customer_id(first_name, last_name)');

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query.order('quotation_date', ascending: false);
      return (response as List)
          .map((e) => Quotation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load quotations: $e');
    }
  }

  Future<Quotation?> getQuotation(String id) async {
    try {
      final response = await _client
          .from('quotations')
          .select('*, customers:customer_id(first_name, last_name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Quotation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load quotation: $e');
    }
  }

  Future<Quotation> createQuotation(Quotation quotation) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = quotation
          .copyWith(
            id: id,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere((key, value) => key == 'items' || key == 'customer_name');

      final response = await _client
          .from('quotations')
          .insert(data)
          .select()
          .single();

      if (quotation.items != null) {
        for (final item in quotation.items!) {
          await _createQuotationItem(id, item);
        }
      }

      return Quotation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create quotation: $e');
    }
  }

  Future<void> _createQuotationItem(String quotationId, QuotationItem item) async {
    final itemData = item
        .copyWith(id: _uuid.v4(), quotationId: quotationId, createdAt: DateTime.now().toUtc())
        .toJson();
    await _client.from('quotation_items').insert(itemData);
  }

  Future<Quotation> updateQuotation(Quotation quotation) async {
    try {
      final data = quotation
          .copyWith(updatedAt: DateTime.now().toUtc(), updatedBy: SupabaseService().currentUser?.id)
          .toJson();
      data.removeWhere((key, value) => key == 'items' || key == 'customer_name');
      final response = await _client
          .from('quotations')
          .update(data)
          .eq('id', quotation.id)
          .select()
          .single();
      return Quotation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update quotation: $e');
    }
  }

  Future<void> deleteQuotation(String id) async {
    try {
      await _client.from('quotations').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete quotation: $e');
    }
  }

  // ---- Sales Invoices ----

  Future<List<SalesInvoice>> getSalesInvoices({
    String? pharmacyId,
    String? customerId,
    SalesInvoiceStatus? status,
  }) async {
    try {
      var query = _client
          .from('sales_invoices')
          .select('*, customers:customer_id(first_name, last_name)');

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query.order('invoice_date', ascending: false);
      return (response as List)
          .map((e) => SalesInvoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sales invoices: $e');
    }
  }

  Future<SalesInvoice?> getSalesInvoice(String id) async {
    try {
      final response = await _client
          .from('sales_invoices')
          .select('*, customers:customer_id(first_name, last_name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return SalesInvoice.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load sales invoice: $e');
    }
  }

  Future<SalesInvoice> createSalesInvoice(SalesInvoice invoice) async {
    try {
      final now = DateTime.now().toUtc();
      final data = invoice
          .copyWith(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere((key, value) => key == 'customer_name');
      final response = await _client
          .from('sales_invoices')
          .insert(data)
          .select()
          .single();
      return SalesInvoice.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create sales invoice: $e');
    }
  }

  Future<SalesInvoice> updateSalesInvoice(SalesInvoice invoice) async {
    try {
      final data = invoice
          .copyWith(updatedAt: DateTime.now().toUtc(), updatedBy: SupabaseService().currentUser?.id)
          .toJson();
      data.removeWhere((key, value) => key == 'customer_name');
      final response = await _client
          .from('sales_invoices')
          .update(data)
          .eq('id', invoice.id)
          .select()
          .single();
      return SalesInvoice.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update sales invoice: $e');
    }
  }

  Future<void> deleteSalesInvoice(String id) async {
    try {
      await _client.from('sales_invoices').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete sales invoice: $e');
    }
  }

  // ---- Invoice Payments ----

  Future<List<InvoicePayment>> getInvoicePayments(String invoiceId) async {
    try {
      final response = await _client
          .from('invoice_payments')
          .select()
          .eq('invoice_id', invoiceId)
          .order('payment_date', ascending: false);
      return (response as List)
          .map((e) => InvoicePayment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load invoice payments: $e');
    }
  }

  // paid_amount et status de la facture sont recalculés par la base
  // (déclencheurs de 20260927050000_sales_invoice_payments_integrity.sql).
  Future<InvoicePayment> createInvoicePayment(InvoicePayment payment) async {
    try {
      final data = payment
          .copyWith(id: _uuid.v4(), createdAt: DateTime.now().toUtc())
          .toJson();
      final response = await _client
          .from('invoice_payments')
          .insert(data)
          .select()
          .single();
      return InvoicePayment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create invoice payment: $e');
    }
  }
}
