import 'package:equatable/equatable.dart';

class CustomerReturnItem extends Equatable {
  final String id;
  final String returnId;
  final String? saleItemId;
  final String? productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String? reasonId;
  final String? reasonText;
  final String? condition; // new, used, damaged, expired
  final DateTime createdAt;
  final String? gsgId;
  final String? gsgOrgId;

  const CustomerReturnItem({
    required this.id,
    required this.returnId,
    this.saleItemId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.reasonId,
    this.reasonText,
    this.condition,
    required this.createdAt,
    this.gsgId,
    this.gsgOrgId,
  });

  CustomerReturnItem copyWith({
    String? id,
    String? returnId,
    String? saleItemId,
    String? productId,
    String? productName,
    int? quantity,
    int? unitPrice,
    int? totalPrice,
    String? reasonId,
    String? reasonText,
    String? condition,
    DateTime? createdAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return CustomerReturnItem(
      id: id ?? this.id,
      returnId: returnId ?? this.returnId,
      saleItemId: saleItemId ?? this.saleItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      reasonId: reasonId ?? this.reasonId,
      reasonText: reasonText ?? this.reasonText,
      condition: condition ?? this.condition,
      createdAt: createdAt ?? this.createdAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'return_id': returnId,
    if (saleItemId != null) 'sale_item_id': saleItemId,
    if (productId != null) 'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    if (reasonId != null) 'reason_id': reasonId,
    if (reasonText != null) 'reason_text': reasonText,
    if (condition != null) 'condition': condition,
    'created_at': createdAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory CustomerReturnItem.fromJson(Map<String, dynamic> json) =>
      CustomerReturnItem(
        id: json['id'] as String,
        returnId: json['return_id'] as String,
        saleItemId: json['sale_item_id'] as String?,
        productId: json['product_id'] as String?,
        productName: json['product_name'] as String,
        quantity: json['quantity'] as int,
        unitPrice: json['unit_price'] as int,
        totalPrice: json['total_price'] as int,
        reasonId: json['reason_id'] as String?,
        reasonText: json['reason_text'] as String?,
        condition: json['condition'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    returnId,
    saleItemId,
    productId,
    productName,
    quantity,
    unitPrice,
    totalPrice,
    reasonId,
    reasonText,
    condition,
    createdAt,
    gsgId,
    gsgOrgId,
  ];

  String get conditionLabel {
    switch (condition) {
      case 'new':
        return 'Neuf';
      case 'used':
        return 'Usagé';
      case 'damaged':
        return 'Endommagé';
      case 'expired':
        return 'Périmé';
      default:
        return condition ?? 'Non spécifié';
    }
  }
}
