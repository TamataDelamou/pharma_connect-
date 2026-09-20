import 'package:equatable/equatable.dart';
import 'customer_order_item.dart';

enum CustomerOrderStatus {
  draft,
  confirmed,
  preparing,
  ready,
  delivered,
  cancelled,
}

extension CustomerOrderStatusExtension on CustomerOrderStatus {
  String get label {
    switch (this) {
      case CustomerOrderStatus.draft:
        return '📝 Brouillon';
      case CustomerOrderStatus.confirmed:
        return '✅ Confirmée';
      case CustomerOrderStatus.preparing:
        return '🔄 En préparation';
      case CustomerOrderStatus.ready:
        return '📦 Prête';
      case CustomerOrderStatus.delivered:
        return '🚚 Livrée';
      case CustomerOrderStatus.cancelled:
        return '❌ Annulée';
    }
  }

  String get icon {
    switch (this) {
      case CustomerOrderStatus.draft:
        return '📝';
      case CustomerOrderStatus.confirmed:
        return '✅';
      case CustomerOrderStatus.preparing:
        return '🔄';
      case CustomerOrderStatus.ready:
        return '📦';
      case CustomerOrderStatus.delivered:
        return '🚚';
      case CustomerOrderStatus.cancelled:
        return '❌';
    }
  }
}

class CustomerOrder extends Equatable {
  final String id;
  final String pharmacyId;
  final String? customerId;
  final String orderNumber;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final CustomerOrderStatus status;
  final int totalAmount;
  final int paidAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final List<CustomerOrderItem>? items;
  final String? customerName;

  const CustomerOrder({
    required this.id,
    required this.pharmacyId,
    this.customerId,
    required this.orderNumber,
    required this.orderDate,
    this.deliveryDate,
    required this.status,
    required this.totalAmount,
    this.paidAmount = 0,
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

  CustomerOrder copyWith({
    String? id,
    String? pharmacyId,
    String? customerId,
    String? orderNumber,
    DateTime? orderDate,
    DateTime? deliveryDate,
    CustomerOrderStatus? status,
    int? totalAmount,
    int? paidAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    List<CustomerOrderItem>? items,
    String? customerName,
  }) {
    return CustomerOrder(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      customerId: customerId ?? this.customerId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
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
  // CustomerReturn.toJson(), a charge du service appelant de les retirer
  // (data.removeWhere(...)) avant tout insert/update si necessaire.
  Map<String, dynamic> toJson() => {
    'id': id,
    'pharmacy_id': pharmacyId,
    if (customerId != null) 'customer_id': customerId,
    'order_number': orderNumber,
    'order_date': orderDate.toIso8601String(),
    if (deliveryDate != null) 'delivery_date': deliveryDate!.toIso8601String(),
    'status': status.name,
    'total_amount': totalAmount,
    'paid_amount': paidAmount,
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

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    // 'customers' : embed Supabase (customers:customer_id(first_name,last_name)),
    // voir SalesService.getCustomerOrders().
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

    List<CustomerOrderItem>? parsedItems;
    final itemsRaw = json['items'];
    if (itemsRaw is List) {
      parsedItems = itemsRaw
          .map((e) => CustomerOrderItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return CustomerOrder(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      customerId: json['customer_id'] as String?,
      orderNumber: json['order_number'] as String,
      orderDate: DateTime.parse(json['order_date'] as String),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      status: CustomerOrderStatus.values.byName(json['status'] as String),
      totalAmount: json['total_amount'] as int,
      paidAmount: json['paid_amount'] as int? ?? 0,
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
    orderNumber,
    orderDate,
    deliveryDate,
    status,
    totalAmount,
    paidAmount,
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

  int get remainingAmount => totalAmount - paidAmount;
  bool get isPaid => paidAmount >= totalAmount;
}
