import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/pos_sale.dart';
import '../models/pos_sale_item.dart';
import '../models/pos_receipt.dart';

class POSService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Sales ----

  Future<POSSale> createSale(POSSale sale) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = sale
          .copyWith(
            id: id,
            status: 'completed',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();

      data.removeWhere(
        (key, value) =>
            key == 'items' || key == 'patient_name' || key == 'cashier_name',
      );

      // Insert sale
      final response = await _client
          .from('pos_sales')
          .insert(data)
          .select()
          .single();

      // Create sale items and update stock
      if (sale.items != null) {
        for (final item in sale.items!) {
          await _createSaleItem(id, item);
          await _updateStock(item);
        }
      }

      // Generate receipt
      await _generateReceipt(id);

      return POSSale.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create sale: $e');
    }
  }

  Future<void> _createSaleItem(String saleId, POSSaleItem item) async {
    final itemData = item
        .copyWith(
          id: _uuid.v4(),
          saleId: saleId,
          createdAt: DateTime.now().toUtc(),
        )
        .toJson();

    await _client.from('pos_sale_items').insert(itemData);
  }

  Future<void> _updateStock(POSSaleItem item) async {
    if (item.batchId != null) {
      await _client
          .from('stock_batches')
          .update({
            'quantity': sqlExpr('quantity - ${item.quantity}'),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', item.batchId);
    }
  }

  Future<void> _generateReceipt(String saleId) async {
    await _client.from('pos_receipts').insert({
      'sale_id': saleId,
      'printed_at': DateTime.now().toUtc().toIso8601String(),
      'printed_by': SupabaseService().currentUser?.id,
    });
  }

  Future<List<POSSale>> getSales({
    String? pharmacyId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from('pos_sales')
          .select(
            '*, patients:patient_id(full_name), cashiers:cashier_id(full_name), items:sale_items(*)',
          )
          .order('created_at', ascending: false)
          .limit(limit);

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }

      final response = await query;
      return (response as List)
          .map((e) => POSSale.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sales: $e');
    }
  }

  Future<POSSale?> getSale(String id) async {
    try {
      final response = await _client
          .from('pos_sales')
          .select(
            '*, patients:patient_id(full_name), cashiers:cashier_id(full_name), items:sale_items(*)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return POSSale.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load sale: $e');
    }
  }

  Future<POSSale> refundSale(String saleId) async {
    try {
      // Update sale status
      final response = await _client
          .from('pos_sales')
          .update({
            'status': 'refunded',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'updated_by': SupabaseService().currentUser?.id,
          })
          .eq('id', saleId)
          .select()
          .single();

      // Restore stock
      final items = await _client
          .from('pos_sale_items')
          .select()
          .eq('sale_id', saleId);

      for (final item in items as List) {
        if (item['batch_id'] != null) {
          await _client
              .from('stock_batches')
              .update({
                'quantity': sqlExpr('quantity + ${item['quantity']}'),
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', item['batch_id']);
        }
      }

      return POSSale.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to refund sale: $e');
    }
  }

  Future<void> cancelSale(String saleId) async {
    try {
      await _client
          .from('pos_sales')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'updated_by': SupabaseService().currentUser?.id,
          })
          .eq('id', saleId);
    } catch (e) {
      throw Exception('Failed to cancel sale: $e');
    }
  }

  // ---- Receipts ----

  Future<POSReceipt?> getReceipt(String saleId) async {
    try {
      final response = await _client
          .from('pos_receipts')
          .select()
          .eq('sale_id', saleId)
          .maybeSingle();
      if (response == null) return null;
      return POSReceipt.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load receipt: $e');
    }
  }

  Future<String> generateReceiptPDF(String saleId) async {
    try {
      final sale = await getSale(saleId);
      if (sale == null) throw Exception('Sale not found');

      // Generate PDF content
      final pdf = await _buildReceiptPDF(sale);

      // Upload to Supabase Storage
      final fileName = 'receipt_${sale.saleNumber}.pdf';
      final path = 'receipts/${sale.pharmacyId}/$fileName';
      await _client.storage.from('receipts').uploadBinary(path, pdf);

      final url = _client.storage.from('receipts').getPublicUrl(path);

      // Update receipt URL
      await _client
          .from('pos_receipts')
          .update({'receipt_url': url})
          .eq('sale_id', saleId);

      return url;
    } catch (e) {
      throw Exception('Failed to generate receipt PDF: $e');
    }
  }

  Future<Uint8List> _buildReceiptPDF(POSSale sale) async {
    // Using pdf package
    final pdf = Document();

    pdf.addPage(
      MultiPage(
        pageFormat: A4,
        margin: const EdgeInsets.all(20),
        build: (context) => [
          Header(
            text: 'PHARMACONNECT',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Header(
            text: 'Reçu de vente #${sale.saleNumber}',
            style: TextStyle(fontSize: 14),
          ),
          Divider(),
          Text(
            'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.createdAt)}',
          ),
          Text('Pharmacie: ${sale.pharmacyId}'),
          if (sale.patientName != null) Text('Patient: ${sale.patientName}'),
          if (sale.cashierName != null) Text('Caissier: ${sale.cashierName}'),
          Divider(),
          Table(
            header: [
              TableCell(
                child: Text(
                  'Produit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TableCell(
                child: Text(
                  'Qté',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TableCell(
                child: Text(
                  'Prix',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TableCell(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows:
                sale.items
                    ?.map(
                      (item) => [
                        TableCell(child: Text(item.productName)),
                        TableCell(child: Text('${item.quantity}')),
                        TableCell(
                          child: Text(CurrencyFormatter.format(item.unitPrice)),
                        ),
                        TableCell(
                          child: Text(
                            CurrencyFormatter.format(item.totalPrice),
                          ),
                        ),
                      ],
                    )
                    .toList() ??
                [],
          ),
          Divider(),
          Text('Total: ${CurrencyFormatter.format(sale.totalAmount)}'),
          Text('Remise: ${CurrencyFormatter.format(sale.discountAmount)}'),
          Text('TVA: ${CurrencyFormatter.format(sale.taxAmount)}'),
          Text(
            'À payer: ${CurrencyFormatter.format(sale.finalAmount)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Paiement: ${sale.paymentLabel}'),
          Divider(),
          Text(
            'Merci de votre visite !',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );

    return await pdf.save();
  }
}
