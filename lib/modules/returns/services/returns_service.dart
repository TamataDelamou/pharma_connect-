import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/customer_return.dart';
import '../models/customer_return_item.dart';
import '../models/supplier_return.dart';
import '../models/return_reason.dart';

class ReturnsService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Customer Returns ----

  Future<List<CustomerReturn>> getCustomerReturns({
    String? pharmacyId,
    String? customerId,
    ReturnStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client
          .from('customer_returns')
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
      if (fromDate != null) {
        query = query.gte('return_date', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('return_date', toDate.toIso8601String());
      }

      final response = await query.order('return_date', ascending: false);
      return (response as List)
          .map((e) => CustomerReturn.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load customer returns: $e');
    }
  }

  Future<CustomerReturn?> getCustomerReturn(String id) async {
    try {
      final response = await _client
          .from('customer_returns')
          .select(
            '*, customers:customer_id(first_name, last_name), items:return_items(*)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return CustomerReturn.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load customer return: $e');
    }
  }

  Future<CustomerReturn> createCustomerReturn(CustomerReturn returnData) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = returnData
          .copyWith(
            id: id,
            status: ReturnStatus.pending,
            returnDate: now,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'items' || key == 'customer_name' || key == 'reason_name',
      );

      final response = await _client
          .from('customer_returns')
          .insert(data)
          .select()
          .single();

      // Create items
      if (returnData.items != null) {
        for (final item in returnData.items!) {
          await _createCustomerReturnItem(id, item);
        }
      }

      return CustomerReturn.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create customer return: $e');
    }
  }

  Future<void> _createCustomerReturnItem(
    String returnId,
    CustomerReturnItem item,
  ) async {
    final itemData = item
        .copyWith(
          id: _uuid.v4(),
          returnId: returnId,
          createdAt: DateTime.now().toUtc(),
        )
        .toJson();
    await _client.from('customer_return_items').insert(itemData);
  }

  Future<CustomerReturn> updateCustomerReturnStatus(
    String id,
    ReturnStatus status, {
    int? refundAmount,
    String? notes,
  }) async {
    try {
      final data = {
        'status': status.name,
        if (refundAmount != null) 'refund_amount': refundAmount,
        if (notes != null) 'notes': notes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('customer_returns')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      // If approved, process refund and restore stock
      if (status == ReturnStatus.approved) {
        await _processCustomerReturn(id);
      }

      return CustomerReturn.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update return status: $e');
    }
  }

  Future<void> _processCustomerReturn(String returnId) async {
    // Get return items
    final items = await _client
        .from('customer_return_items')
        .select()
        .eq('return_id', returnId);

    // Restore stock for each item
    for (final item in items as List) {
      final saleItemId = item['sale_item_id'] as String?;
      if (saleItemId != null) {
        await _restoreStock(saleItemId, item['quantity'] as int, returnId);
      }
    }
  }

  Future<void> _restoreStock(
    String saleItemId,
    int quantity,
    String returnId,
  ) async {
    final saleItem = await _client
        .from('pos_sale_items')
        .select('batch_id')
        .eq('id', saleItemId)
        .maybeSingle();

    final batchId = saleItem?['batch_id'] as String?;
    if (batchId == null) return;

    await _client.rpc(
      'stock_apply_movement',
      params: {
        'p_batch_id': batchId,
        'p_delta': quantity,
        'p_type': 'adjustment',
        'p_reference_id': returnId,
        'p_reason': 'Retour client',
      },
    );
  }

  // ---- Return Reasons ----

  Future<List<ReturnReason>> getReturnReasons({String? category}) async {
    try {
      var query = _client
          .from('return_reasons')
          .select()
          .eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((e) => ReturnReason.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load return reasons: $e');
    }
  }

  // ---- Supplier Returns (similar pattern) ----

  Future<List<SupplierReturn>> getSupplierReturns({
    String? pharmacyId,
    String? supplierId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    // Implementation similar to customer returns
    return [];
  }

  Future<SupplierReturn?> getSupplierReturn(String id) async {
    // Implementation
    return null;
  }

  Future<SupplierReturn> createSupplierReturn(SupplierReturn returnData) async {
    // Implementation
    throw UnimplementedError();
  }
}
