class Invoice {
  final String id;
  final String transactionId;
  final String invoiceNumber;
  final String pharmacyName;
  final String pharmacyAddress;
  final String pharmacyPhone;
  final String patientName;
  final String patientAddress;
  final String patientPhone;
  final String patientEmail;
  final DateTime issuedAt;
  final DateTime? dueDate;
  final List<InvoiceItem> items;
  final int subtotal;
  final int tax;
  final int discount;
  final int total;
  final String status; // paid, unpaid, cancelled, refunded
  final String? pdfUrl;

  const Invoice({
    required this.id,
    required this.transactionId,
    required this.invoiceNumber,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.pharmacyPhone,
    required this.patientName,
    required this.patientAddress,
    required this.patientPhone,
    required this.patientEmail,
    required this.issuedAt,
    this.dueDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.status,
    this.pdfUrl,
  });
}

class InvoiceItem {
  final String id;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int total;
  final String? dosage;

  const InvoiceItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.dosage,
  });
}
