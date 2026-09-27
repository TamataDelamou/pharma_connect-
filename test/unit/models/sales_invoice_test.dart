import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/modules/sales/models/sales_invoice.dart';

// C185 (décision du porteur du projet, 27/09/2026) : « en retard » est calculé
// à la volée, jamais stocké : status = sent, dueDate non nulle et antérieure à
// la date du jour. Une facture payée, en brouillon ou annulée n'est jamais en
// retard. Échéances relatives à aujourd'hui pour rester indépendant de la date
// d'exécution.
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));

  SalesInvoice invoice(SalesInvoiceStatus status, DateTime? dueDate) =>
      SalesInvoice(
        id: 'inv-1',
        pharmacyId: 'ph-1',
        invoiceNumber: 'F-001',
        invoiceDate: today.subtract(const Duration(days: 30)),
        dueDate: dueDate,
        totalAmount: 10000,
        status: status,
        createdAt: today,
        updatedAt: today,
      );

  group('SalesInvoice.isOverdue / displayStatus', () {
    test('envoyée échue : en retard', () {
      final i = invoice(SalesInvoiceStatus.sent, yesterday);
      expect(i.isOverdue, isTrue);
      expect(i.displayStatus, SalesInvoiceStatus.overdue);
    });

    test('envoyée non échue : pas en retard', () {
      final i = invoice(SalesInvoiceStatus.sent, tomorrow);
      expect(i.isOverdue, isFalse);
      expect(i.displayStatus, SalesInvoiceStatus.sent);
    });

    test('envoyée échéant aujourd\'hui : pas en retard (date seule)', () {
      final i = invoice(
        SalesInvoiceStatus.sent,
        DateTime(today.year, today.month, today.day, 23, 59),
      );
      expect(i.isOverdue, isFalse);
      expect(i.displayStatus, SalesInvoiceStatus.sent);
    });

    test('envoyée sans échéance : pas en retard', () {
      final i = invoice(SalesInvoiceStatus.sent, null);
      expect(i.isOverdue, isFalse);
      expect(i.displayStatus, SalesInvoiceStatus.sent);
    });

    test('payée échue : pas en retard', () {
      final i = invoice(SalesInvoiceStatus.paid, yesterday);
      expect(i.isOverdue, isFalse);
      expect(i.displayStatus, SalesInvoiceStatus.paid);
    });

    test('brouillon échu : pas en retard', () {
      final i = invoice(SalesInvoiceStatus.draft, yesterday);
      expect(i.isOverdue, isFalse);
      expect(i.displayStatus, SalesInvoiceStatus.draft);
    });

    test('annulée échue : pas en retard', () {
      final i = invoice(SalesInvoiceStatus.cancelled, yesterday);
      expect(i.isOverdue, isFalse);
      expect(i.displayStatus, SalesInvoiceStatus.cancelled);
    });

    test('toJson n\'envoie jamais overdue', () {
      final i = invoice(SalesInvoiceStatus.overdue, yesterday);
      expect(i.toJson()['status'], 'sent');
      expect(invoice(SalesInvoiceStatus.sent, yesterday).toJson()['status'],
          'sent');
    });
  });
}
