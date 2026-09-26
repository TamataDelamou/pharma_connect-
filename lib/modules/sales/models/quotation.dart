import 'package:equatable/equatable.dart';
import 'quotation_item.dart';

enum QuotationStatus { draft, sent, accepted, rejected, expired }

extension QuotationStatusExtension on QuotationStatus {
  String get label {
    switch (this) {
      case QuotationStatus.draft:
        return '📝 Brouillon';
      case QuotationStatus.sent:
        return '📤 Envoyé';
      case QuotationStatus.accepted:
        return '✅ Accepté';
      case QuotationStatus.rejected:
        return '❌ Refusé';
      case QuotationStatus.expired:
        return '⏳ Expiré';
    }
  }

  String get icon {
    switch (this) {
      case QuotationStatus.draft:
        return '📝';
      case QuotationStatus.sent:
        return '📤';
      case QuotationStatus.accepted:
        return '✅';
      case QuotationStatus.rejected:
        return '❌';
      case QuotationStatus.expired:
        return '⏳';
    }
  }
}

class Quotation extends Equatable {
  final String id;
  final String pharmacyId;
  final String? customerId;
  final String quotationNumber;
  final DateTime quotationDate;
  final DateTime? validUntil;
  final int totalAmount;
  final QuotationStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final List<QuotationItem>? items;
  final String? customerName;

  const Quotation({
    required this.id,
    required this.pharmacyId,
    this.customerId,
    required this.quotationNumber,
    required this.quotationDate,
    this.validUntil,
    required this.totalAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.items,
    this.customerName,
  });

  Quotation copyWith({
    String? id,
    String? pharmacyId,
    String? customerId,
    String? quotationNumber,
    DateTime? quotationDate,
    DateTime? validUntil,
    int? totalAmount,
    QuotationStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    List<QuotationItem>? items,
    String? customerName,
  }) {
    return Quotation(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      customerId: customerId ?? this.customerId,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      quotationDate: quotationDate ?? this.quotationDate,
      validUntil: validUntil ?? this.validUntil,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
    );
  }

  // Inclut volontairement 'items'/'customer_name' : motif deja etabli par
  // CustomerOrder.toJson(), a charge du service appelant de les retirer
  // (data.removeWhere(...)) avant tout insert/update si necessaire.
  Map<String, dynamic> toJson() => {
    'id': id,
    'pharmacy_id': pharmacyId,
    if (customerId != null) 'customer_id': customerId,
    'quotation_number': quotationNumber,
    'quotation_date': quotationDate.toIso8601String(),
    if (validUntil != null)
      'valid_until': validUntil!.toIso8601String().split('T').first,
    'total_amount': totalAmount,
    'status': status.name,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
    if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
    if (customerName != null) 'customer_name': customerName,
  };

  factory Quotation.fromJson(Map<String, dynamic> json) {
    // 'customers' : embed Supabase (customers:customer_id(first_name,last_name)),
    // voir SalesService.getQuotations().
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

    List<QuotationItem>? parsedItems;
    final itemsRaw = json['items'];
    if (itemsRaw is List) {
      parsedItems = itemsRaw
          .map((e) => QuotationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Quotation(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      customerId: json['customer_id'] as String?,
      quotationNumber: json['quotation_number'] as String,
      quotationDate: DateTime.parse(json['quotation_date'] as String),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      totalAmount: json['total_amount'] as int,
      status: QuotationStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      gsgId: json['gsg_id'] as String?,
      gsgOrgId: json['gsg_org_id'] as String?,
      items: parsedItems,
      customerName: derivedCustomerName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pharmacyId,
    customerId,
    quotationNumber,
    quotationDate,
    validUntil,
    totalAmount,
    status,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    items,
    customerName,
  ];
}
