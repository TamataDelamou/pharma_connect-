import 'package:equatable/equatable.dart';
import 'customer_return_item.dart';

enum ReturnStatus {
  pending,
  approved,
  rejected,
  completed,
  cancelled,
}

extension ReturnStatusExtension on ReturnStatus {
  String get label {
    switch (this) {
      case ReturnStatus.pending:
        return '⏳ En attente';
      case ReturnStatus.approved:
        return '✅ Approuvé';
      case ReturnStatus.rejected:
        return '❌ Rejeté';
      case ReturnStatus.completed:
        return '🏁 Terminé';
      case ReturnStatus.cancelled:
        return '🚫 Annulé';
    }
  }

  String get color {
    switch (this) {
      case ReturnStatus.pending:
        return '#F59E0B';
      case ReturnStatus.approved:
        return '#10B981';
      case ReturnStatus.rejected:
        return '#EF4444';
      case ReturnStatus.completed:
        return '#00D9FF';
      case ReturnStatus.cancelled:
        return '#9CA3AF';
    }
  }
}

class CustomerReturn extends Equatable {
  final String id;
  final String pharmacyId;
  final String? customerId;
  final String? saleId;
  final String returnNumber;
  final DateTime returnDate;
  final String? reasonId;
  final String? reasonText;
  final ReturnStatus status;
  final int totalAmount;
  final int? refundAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived (jamais persistés tels quels : alimentés par les embeds
  // Supabase de returns_service.dart, retirés du payload par
  // data.removeWhere(...) avant tout insert/update).
  final List<CustomerReturnItem>? items;
  final String? customerName;
  final String? reasonName;

  const CustomerReturn({
    required this.id,
    required this.pharmacyId,
    this.customerId,
    this.saleId,
    required this.returnNumber,
    required this.returnDate,
    this.reasonId,
    this.reasonText,
    required this.status,
    required this.totalAmount,
    this.refundAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.items,
    this.customerName,
    this.reasonName,
  });

  CustomerReturn copyWith({
    String? id,
    String? pharmacyId,
    String? customerId,
    String? saleId,
    String? returnNumber,
    DateTime? returnDate,
    String? reasonId,
    String? reasonText,
    ReturnStatus? status,
    int? totalAmount,
    int? refundAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    List<CustomerReturnItem>? items,
    String? customerName,
    String? reasonName,
  }) {
    return CustomerReturn(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      customerId: customerId ?? this.customerId,
      saleId: saleId ?? this.saleId,
      returnNumber: returnNumber ?? this.returnNumber,
      returnDate: returnDate ?? this.returnDate,
      reasonId: reasonId ?? this.reasonId,
      reasonText: reasonText ?? this.reasonText,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      refundAmount: refundAmount ?? this.refundAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      reasonName: reasonName ?? this.reasonName,
    );
  }

  // Inclut volontairement 'items'/'customer_name'/'reason_name' : ces clés
  // sont retirées par returns_service.dart (data.removeWhere(...)) avant
  // tout insert/update, comportement déjà écrit là-bas, non modifié ici.
  Map<String, dynamic> toJson() => {
    'id': id,
    'pharmacy_id': pharmacyId,
    if (customerId != null) 'customer_id': customerId,
    if (saleId != null) 'sale_id': saleId,
    'return_number': returnNumber,
    'return_date': returnDate.toIso8601String(),
    if (reasonId != null) 'reason_id': reasonId,
    if (reasonText != null) 'reason_text': reasonText,
    'status': status.name,
    'total_amount': totalAmount,
    if (refundAmount != null) 'refund_amount': refundAmount,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
    if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
    if (customerName != null) 'customer_name': customerName,
    if (reasonName != null) 'reason_name': reasonName,
  };

  factory CustomerReturn.fromJson(Map<String, dynamic> json) {
    // 'customers' : embed Supabase (customers:customer_id(first_name,last_name)),
    // 'items' : embed brut (liste de maps) tel que renvoyé par PostgREST ;
    // 'customer_name'/'reason_name' : formes déjà aplaties, si présentes.
    String? derivedCustomerName = json['customer_name'] as String?;
    final customersEmbed = json['customers'];
    if (derivedCustomerName == null && customersEmbed is Map) {
      final first = customersEmbed['first_name'] as String?;
      final last = customersEmbed['last_name'] as String?;
      if (first != null || last != null) {
        derivedCustomerName = [first, last]
            .where((e) => e != null && e.isNotEmpty)
            .join(' ');
      }
    }

    List<CustomerReturnItem>? parsedItems;
    final itemsRaw = json['items'];
    if (itemsRaw is List) {
      parsedItems = itemsRaw
          .map((e) => CustomerReturnItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return CustomerReturn(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      customerId: json['customer_id'] as String?,
      saleId: json['sale_id'] as String?,
      returnNumber: json['return_number'] as String,
      returnDate: DateTime.parse(json['return_date'] as String),
      reasonId: json['reason_id'] as String?,
      reasonText: json['reason_text'] as String?,
      status: ReturnStatus.values.byName(json['status'] as String),
      totalAmount: json['total_amount'] as int,
      refundAmount: json['refund_amount'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      gsgId: json['gsg_id'] as String?,
      gsgOrgId: json['gsg_org_id'] as String?,
      items: parsedItems,
      customerName: derivedCustomerName,
      reasonName: json['reason_name'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pharmacyId,
    customerId,
    saleId,
    returnNumber,
    returnDate,
    reasonId,
    reasonText,
    status,
    totalAmount,
    refundAmount,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    items,
    customerName,
    reasonName,
  ];

  bool get isPending => status == ReturnStatus.pending;
  bool get isApproved => status == ReturnStatus.approved;
  bool get isCompleted => status == ReturnStatus.completed;
}
