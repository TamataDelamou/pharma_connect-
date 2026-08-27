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

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'] as String,
    transactionId: json['transaction_id'] as String,
    invoiceNumber: json['invoice_number'] as String,
    pharmacyName: json['pharmacy_name'] as String,
    pharmacyAddress: json['pharmacy_address'] as String,
    pharmacyPhone: json['pharmacy_phone'] as String,
    patientName: json['patient_name'] as String,
    patientAddress: json['patient_address'] as String? ?? '',
    patientPhone: json['patient_phone'] as String,
    patientEmail: json['patient_email'] as String? ?? '',
    issuedAt: DateTime.parse(json['issued_at'] as String),
    dueDate: json['due_date'] != null
        ? DateTime.parse(json['due_date'] as String)
        : null,
    items: (json['invoice_items'] as List<dynamic>? ?? [])
        .map((i) => InvoiceItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    subtotal: json['subtotal'] as int,
    tax: json['tax'] as int? ?? 0,
    discount: json['discount'] as int? ?? 0,
    total: json['total'] as int,
    status: json['status'] as String,
    pdfUrl: json['pdf_url'] as String?,
  );

  // items n'est jamais écrit ici : invoice_items est une table séparée.
  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction_id': transactionId,
    'invoice_number': invoiceNumber,
    'pharmacy_name': pharmacyName,
    'pharmacy_address': pharmacyAddress,
    'pharmacy_phone': pharmacyPhone,
    'patient_name': patientName,
    'patient_address': patientAddress,
    'patient_phone': patientPhone,
    'patient_email': patientEmail,
    'issued_at': issuedAt.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'subtotal': subtotal,
    'tax': tax,
    'discount': discount,
    'total': total,
    'status': status,
    'pdf_url': pdfUrl,
  };
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

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    id: json['id'] as String,
    productName: json['product_name'] as String,
    quantity: json['quantity'] as int,
    unitPrice: json['unit_price'] as int,
    total: json['total'] as int,
    dosage: json['dosage'] as String?,
  );

  Map<String, dynamic> toJson({required String invoiceId}) => {
    'id': id,
    'invoice_id': invoiceId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total': total,
    'dosage': dosage,
  };
}
