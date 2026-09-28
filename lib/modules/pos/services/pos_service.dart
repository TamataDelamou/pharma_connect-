import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:uuid/uuid.dart';
import '../models/pos_sale.dart';
import '../models/pos_sale_item.dart';
import '../models/pos_receipt.dart';

/// C193 : usage d'un lien signé vers un reçu. Durées décidées par le porteur
/// du projet le 28/09/2026.
enum ReceiptLinkPurpose { consultation, export }

class POSService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  static const receiptConsultationLinkTtl = Duration(minutes: 15);
  static const receiptExportLinkTtl = Duration(hours: 24);

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
          await _updateStock(item, id);
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

  Future<void> _updateStock(POSSaleItem item, String saleId) async {
    final batchId = item.batchId;
    if (batchId == null) return;
    await _client.rpc(
      'stock_apply_movement',
      params: {
        'p_batch_id': batchId,
        'p_delta': -item.quantity,
        'p_type': 'sale',
        'p_reference_id': saleId,
        'p_reason': 'Vente POS',
      },
    );
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
            '*, patients:patient_id(full_name), cashiers:cashier_id(full_name), items:pos_sale_items(*)',
          );

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

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
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
            '*, patients:patient_id(full_name), cashiers:cashier_id(full_name), items:pos_sale_items(*)',
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
        final batchId = item['batch_id'] as String?;
        if (batchId != null) {
          await _client.rpc(
            'stock_apply_movement',
            params: {
              'p_batch_id': batchId,
              'p_delta': item['quantity'] as int,
              'p_type': 'adjustment',
              'p_reference_id': saleId,
              'p_reason': 'Remboursement vente POS',
            },
          );
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

      // C193 : bucket privé ; chemin <pharmacy_id>/<sale_id>.pdf, contrôlé
      // par les policies storage.objects (is_pharmacy_staff).
      final path = '${sale.pharmacyId}/${sale.id}.pdf';
      await _client.storage
          .from('receipts')
          .uploadBinary(
            path,
            pdf,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      await _client
          .from('pos_receipts')
          .update({'receipt_path': path})
          .eq('sale_id', saleId);

      return path;
    } catch (e) {
      throw Exception('Failed to generate receipt PDF: $e');
    }
  }

  Future<String> _getReceiptPath(String saleId) async {
    final row = await _client
        .from('pos_receipts')
        .select('receipt_path')
        .eq('sale_id', saleId)
        .maybeSingle();
    final path = row?['receipt_path'] as String?;
    if (path == null) {
      throw Exception('Reçu PDF non généré pour cette vente');
    }
    return path;
  }

  /// Consultation dans l'app : téléchargement authentifié, lié à la session
  /// (jeton de l'utilisateur connecté). Aucun lien n'est créé.
  Future<Uint8List> downloadReceiptPdf(String saleId) async {
    final path = await _getReceiptPath(saleId);
    return _client.storage.from('receipts').download(path);
  }

  /// Lien signé à durée limitée : 15 min (consultation hors de l'app) ou
  /// 24 h (export / téléchargement). Seul un membre du personnel de
  /// l'officine peut le créer ; une fois créé, il est valable pour quiconque
  /// le détient jusqu'à son expiration.
  Future<String> createReceiptLink(
    String saleId,
    ReceiptLinkPurpose purpose,
  ) async {
    final path = await _getReceiptPath(saleId);
    final ttl = purpose == ReceiptLinkPurpose.export
        ? receiptExportLinkTtl
        : receiptConsultationLinkTtl;
    return _client.storage
        .from('receipts')
        .createSignedUrl(path, ttl.inSeconds);
  }

  Future<Uint8List> _buildReceiptPDF(POSSale sale) async {
    final pdf = pw.Document();
    final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Header(
            text: 'PHARMACONNECT',
            textStyle: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Header(
            text: 'Reçu de vente #${sale.saleNumber}',
            textStyle: const pw.TextStyle(fontSize: 14),
          ),
          pw.Divider(),
          pw.Text(
            'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.createdAt)}',
          ),
          pw.Text('Pharmacie: ${sale.pharmacyId}'),
          if (sale.patientName != null) pw.Text('Patient: ${sale.patientName}'),
          if (sale.cashierName != null)
            pw.Text('Caissier: ${sale.cashierName}'),
          pw.Divider(),
          pw.TableHelper.fromTextArray(
            headers: ['Produit', 'Qté', 'Prix', 'Total'],
            headerStyle: bold,
            data: [
              for (final item in sale.items ?? const <POSSaleItem>[])
                [
                  item.productName,
                  '${item.quantity}',
                  CurrencyFormatter.format(item.unitPrice),
                  CurrencyFormatter.format(item.totalPrice),
                ],
            ],
          ),
          pw.Divider(),
          pw.Text('Total: ${CurrencyFormatter.format(sale.totalAmount)}'),
          pw.Text('Remise: ${CurrencyFormatter.format(sale.discountAmount)}'),
          pw.Text('TVA: ${CurrencyFormatter.format(sale.taxAmount)}'),
          pw.Text(
            'À payer: ${CurrencyFormatter.format(sale.finalAmount)}',
            style: bold,
          ),
          pw.Text('Paiement: ${sale.paymentLabel}'),
          pw.Divider(),
          pw.Text(
            'Merci de votre visite !',
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
