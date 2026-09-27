import 'package:equatable/equatable.dart';

enum SalesInvoiceStatus { draft, sent, paid, overdue, cancelled }

extension SalesInvoiceStatusExtension on SalesInvoiceStatus {
  String get label {
    switch (this) {
      case SalesInvoiceStatus.draft:
        return '📝 Brouillon';
      case SalesInvoiceStatus.sent:
        return '📤 Envoyée';
      case SalesInvoiceStatus.paid:
        return '✅ Payée';
      case SalesInvoiceStatus.overdue:
        return '⏰ En retard';
      case SalesInvoiceStatus.cancelled:
        return '❌ Annulée';
    }
  }

  String get icon {
    switch (this) {
      case SalesInvoiceStatus.draft:
        return '📝';
      case SalesInvoiceStatus.sent:
        return '📤';
      case SalesInvoiceStatus.paid:
        return '✅';
      case SalesInvoiceStatus.overdue:
        return '⏰';
      case SalesInvoiceStatus.cancelled:
        return '❌';
    }
  }
}

class SalesInvoice extends Equatable {
  final String id;
  final String pharmacyId;
  final String? customerId;
  final String? saleId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final int totalAmount;
  final int paidAmount;
  final SalesInvoiceStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? customerName;

  const SalesInvoice({
    required this.id,
    required this.pharmacyId,
    this.customerId,
    this.saleId,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.customerName,
  });

  SalesInvoice copyWith({
    String? id,
    String? pharmacyId,
    String? customerId,
    String? saleId,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    int? totalAmount,
    int? paidAmount,
    SalesInvoiceStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? customerName,
  }) {
    return SalesInvoice(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      customerId: customerId ?? this.customerId,
      saleId: saleId ?? this.saleId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      customerName: customerName ?? this.customerName,
    );
  }

  // Inclut volontairement 'customer_name' : motif deja etabli par
  // CustomerOrder.toJson(), a charge du service appelant de le retirer
  // (data.removeWhere(...)) avant tout insert/update si necessaire.
  Map<String, dynamic> toJson() => {
    'id': id,
    'pharmacy_id': pharmacyId,
    if (customerId != null) 'customer_id': customerId,
    if (saleId != null) 'sale_id': saleId,
    'invoice_number': invoiceNumber,
    'invoice_date': invoiceDate.toIso8601String(),
    if (dueDate != null)
      'due_date': dueDate!.toIso8601String().split('T').first,
    'total_amount': totalAmount,
    'paid_amount': paidAmount,
    'status': status.name,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
    if (customerName != null) 'customer_name': customerName,
  };

  factory SalesInvoice.fromJson(Map<String, dynamic> json) {
    // 'customers' : embed Supabase (customers:customer_id(first_name,last_name)),
    // voir SalesService.getSalesInvoices().
    String? derivedCustomerName = json['customer_name'] as String?;
    final customersEmbed = json['customers'];
    if (derivedCustomerName == null && customersEmbed is Map) {
      final first = customersEmbed['first_name'] as String?;
      final last = customersEmbed['last_name'] as String?;
      if (first != null || last != null) {
        derivedCustomerName = [
          first,
          last,
        ].where((e) => e != null && e.isNotEmpty).join(' ');
      }
    }

    return SalesInvoice(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      customerId: json['customer_id'] as String?,
      saleId: json['sale_id'] as String?,
      invoiceNumber: json['invoice_number'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      totalAmount: json['total_amount'] as int,
      paidAmount: json['paid_amount'] as int? ?? 0,
      status: SalesInvoiceStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      gsgId: json['gsg_id'] as String?,
      gsgOrgId: json['gsg_org_id'] as String?,
      customerName: derivedCustomerName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pharmacyId,
    customerId,
    saleId,
    invoiceNumber,
    invoiceDate,
    dueDate,
    totalAmount,
    paidAmount,
    status,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    customerName,
  ];

  int get remainingAmount => totalAmount - paidAmount;
  bool get isPaid => status == SalesInvoiceStatus.paid;
}
