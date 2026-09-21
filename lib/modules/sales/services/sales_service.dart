import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/customer_order.dart';
import '../models/customer_order_item.dart';
import '../models/quotation.dart';
import '../models/invoice.dart';
import '../models/supplier_order.dart';

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

  // Continue with order creation, quotations, invoices, supplier orders...
}
