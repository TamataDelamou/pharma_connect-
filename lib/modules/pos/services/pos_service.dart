import 'dart:typed_data';
import 'package:pharma_connect/core/utils/user_message.dart';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FileOptions, PostgrestException;
import '../models/pos_sale.dart';
import '../models/pos_sale_item.dart';
import '../models/pos_receipt.dart';
import '../models/stock_product.dart';

/// C193 : usage d'un lien signé vers un reçu. Durées décidées par le porteur
/// du projet le 28/09/2026.
enum ReceiptLinkPurpose { consultation, export }

/// C201 : refus du serveur lors d'une vente (stock insuffisant, lot périmé,
/// accès refusé…), message lisible tel qu'affiché à l'utilisateur.
class POSSaleException implements UserFacingException {
  @override
  final String message;
  const POSSaleException(this.message);

  @override
  String toString() => message;
}

/// C204 : refus du serveur lors d'un remboursement, message lisible tel
/// qu'affiché à l'utilisateur.
class POSRefundException implements UserFacingException {
  @override
  final String message;
  const POSRefundException(this.message);

  @override
  String toString() => message;
}

class POSService {
  final _client = SupabaseService().client;

  static const receiptConsultationLinkTtl = Duration(minutes: 15);
  static const receiptExportLinkTtl = Duration(hours: 24);

  // ---- Sales ----

  /// C197 : vente complète (vente, lignes, mouvements de stock, reçu) en une
  /// seule transaction côté serveur. Caissier, auteur et statut sont fixés
  /// par la RPC, pas par le client.
  Future<POSSale> createSale(POSSale sale) async {
    try {
      final saleId =
          await _client.rpc(
                'pos_create_sale',
                params: {
                  'p_pharmacy_id': sale.pharmacyId,
                  'p_payment_method': sale.paymentMethod,
                  'p_total_amount': sale.totalAmount,
                  'p_discount_amount': sale.discountAmount,
                  'p_tax_amount': sale.taxAmount,
                  'p_final_amount': sale.finalAmount,
                  'p_patient_id': sale.patientId,
                  'p_notes': sale.notes,
                  'p_items': [
                    for (final item in sale.items ?? const <POSSaleItem>[])
                      {
                        'product_id': item.productId,
                        'product_name': item.productName,
                        'quantity': item.quantity,
                        'unit_price': item.unitPrice,
                        'total_price': item.totalPrice,
                        'batch_id': item.batchId,
                        'discount_percentage': item.discountPercentage,
                        'notes': item.notes,
                        'prescription_checked': item.prescriptionChecked,
                      },
                  ],
                },
              )
              as String;

      final created = await getSale(saleId);
      if (created == null) throw Exception('Vente créée mais introuvable');
      return created;
    } on PostgrestException catch (e) {
      throw POSSaleException(serverMessage(e.message));
    } catch (e) {
      throw Exception('Failed to create sale: $e');
    }
  }

  /// C201 / D60 : produits du stock de l'officine pour l'encaissement (prix,
  /// quantité vendable hors lots périmés et réservés, ordonnance). Recherche
  /// sur le nom et la DCI ; sans [query], les premiers produits du stock.
  Future<List<StockProduct>> searchStockProducts(
    String pharmacyId, {
    String? query,
    int limit = 30,
  }) async {
    final trimmed = query?.trim();
    try {
      final rows =
          await _client.rpc(
                'pos_search_stock_products',
                params: {
                  'p_pharmacy_id': pharmacyId,
                  'p_query': (trimmed == null || trimmed.isEmpty)
                      ? null
                      : trimmed,
                  'p_limit': limit,
                },
              )
              as List<dynamic>;
      return rows
          .map((row) => StockProduct.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw POSSaleException(serverMessage(e.message));
    }
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

  /// C197 / C204 : remboursement atomique. Le serveur fait foi pour la règle
  /// (jour même et plafond de l'officine hors titulaire, motif obligatoire,
  /// destination du stock) : elle n'est pas reproduite ici.
  /// [stockDisposition] : 'restock' (remise en stock) ou 'quarantine'.
  Future<POSSale> refundSale(
    String saleId, {
    required String reason,
    required String stockDisposition,
  }) async {
    try {
      await _client.rpc(
        'pos_refund_sale',
        params: {
          'p_sale_id': saleId,
          'p_reason': reason,
          'p_disposition': stockDisposition,
        },
      );
    } on PostgrestException catch (e) {
      throw POSRefundException(serverMessage(e.message));
    } catch (e) {
      throw Exception('Failed to refund sale: $e');
    }
    final refunded = await getSale(saleId);
    if (refunded == null) {
      throw Exception('Vente introuvable après remboursement');
    }
    return refunded;
  }

  /// C204 : remboursements dont refunded_at tombe dans la période. Les
  /// remboursements antérieurs à C204 (refunded_at null) n'y figurent pas.
  Future<List<POSSale>> getRefunds({
    required String pharmacyId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final response = await _client
          .from('pos_sales')
          .select('*, refunders:refunded_by(full_name)')
          .eq('pharmacy_id', pharmacyId)
          .eq('status', 'refunded')
          .gte('refunded_at', fromDate.toUtc().toIso8601String())
          .lte('refunded_at', toDate.toUtc().toIso8601String())
          .order('refunded_at', ascending: false);
      return (response as List)
          .map((e) => POSSale.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load refunds: $e');
    }
  }

  /// Message d'erreur serveur (« POS: … », « STK: … », sans accents) rendu
  /// lisible : préfixe technique retiré, accents rétablis sur les mots des
  /// messages POS, montants groupés par milliers.
  static String serverMessage(String raw) {
    var message = raw.replaceFirst(RegExp(r'^(POS|STK): '), '');
    const accents = {
      'reserve au titulaire': 'réservé au titulaire',
      'superieur': 'supérieur',
      'precedent': 'précédent',
      'acces refuse': 'accès refusé',
      'completee': 'complétée',
      'remboursee': 'remboursée',
      'a preciser': 'à préciser',
      'est perime': 'est périmé',
      'doit designer': 'doit désigner',
      'incoherent': 'incohérent',
      'different de': 'différent de',
      'a 1 pres': 'à 1 près',
      'non renseigne': 'non renseigné',
      'en especes': 'en espèces',
      // C240 : lot rappelé.
      'est rappele': 'est rappelé',
      'unite(s) en lot rappele': 'unité(s) en lot rappelé',
      'a retirer de la vente': 'à retirer de la vente',
      'du regulateur': 'du régulateur',
      'signale en tracabilite': 'signalé en traçabilité',
    };
    accents.forEach((from, to) => message = message.replaceAll(from, to));
    message = message.replaceAllMapped(
      RegExp(r'(montant|plafond) (\d+)'),
      (m) => '${m[1]} ${_groupThousands(m[2]!)}',
    );
    if (message.isEmpty) return message;
    return message[0].toUpperCase() + message.substring(1);
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
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
