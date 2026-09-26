import 'package:equatable/equatable.dart';

class QuotationItem extends Equatable {
  final String id;
  final String quotationId;
  final String? productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String? notes;
  final DateTime createdAt;
  final String? gsgId;
  final String? gsgOrgId;

  const QuotationItem({
    required this.id,
    required this.quotationId,
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

  QuotationItem copyWith({
    String? id,
    String? quotationId,
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
    return QuotationItem(
      id: id ?? this.id,
      quotationId: quotationId ?? this.quotationId,
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
    'quotation_id': quotationId,
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

  factory QuotationItem.fromJson(Map<String, dynamic> json) => QuotationItem(
    id: json['id'] as String,
    quotationId: json['quotation_id'] as String,
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
    quotationId,
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
