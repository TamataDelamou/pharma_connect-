import 'package:equatable/equatable.dart';

// Modele absent du depot jusqu'ici (voir C154-bis) : customer_order.dart et
// sales_service.dart importent et utilisent ce type sans qu'aucun fichier ne
// le declare. Cree ici a partir du schema reel de
// supabase/migrations/20260829008000_sales_management.sql (table
// customer_order_items), pattern identique a CustomerReturnItem.
class CustomerOrderItem extends Equatable {
  final String id;
  final String orderId;
  final String? productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String? notes;
  final DateTime createdAt;
  final String? gsgId;
  final String? gsgOrgId;

  const CustomerOrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    this.gsgId,
    this.gsgOrgId,
  });

  CustomerOrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    int? quantity,
    int? unitPrice,
    int? totalPrice,
    String? notes,
    DateTime? createdAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return CustomerOrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    if (productId != null) 'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) =>
      CustomerOrderItem(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        productId: json['product_id'] as String?,
        productName: json['product_name'] as String,
        quantity: json['quantity'] as int,
        unitPrice: json['unit_price'] as int,
        totalPrice: json['total_price'] as int,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    orderId,
    productId,
    productName,
    quantity,
    unitPrice,
    totalPrice,
    notes,
    createdAt,
    gsgId,
    gsgOrgId,
  ];
}
