import 'package:equatable/equatable.dart';

class B2BOffer extends Equatable {
  final String id;
  final String sellerPharmacyId;
  final String? productId;
  final String productName;
  final String? description;
  final int price;
  final int quantity;
  final String unit;
  final int minOrderQuantity;
  final DateTime? expiryDate;
  final String status; // active, expired, sold_out, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? sellerName;
  final bool? isNegotiable;

  const B2BOffer({
    required this.id,
    required this.sellerPharmacyId,
    this.productId,
    required this.productName,
    this.description,
    required this.price,
    required this.quantity,
    this.unit = 'unité',
    this.minOrderQuantity = 1,
    this.expiryDate,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.sellerName,
    this.isNegotiable,
  });

  B2BOffer copyWith({
    String? id,
    String? sellerPharmacyId,
    String? productId,
    String? productName,
    String? description,
    int? price,
    int? quantity,
    String? unit,
    int? minOrderQuantity,
    DateTime? expiryDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? sellerName,
    bool? isNegotiable,
  }) {
    return B2BOffer(
      id: id ?? this.id,
      sellerPharmacyId: sellerPharmacyId ?? this.sellerPharmacyId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      sellerName: sellerName ?? this.sellerName,
      isNegotiable: isNegotiable ?? this.isNegotiable,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_pharmacy_id': sellerPharmacyId,
    if (productId != null) 'product_id': productId,
    'product_name': productName,
    if (description != null) 'description': description,
    'price': price,
    'quantity': quantity,
    'unit': unit,
    'min_order_quantity': minOrderQuantity,
    if (expiryDate != null)
      'expiry_date': expiryDate!.toIso8601String().split('T').first,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory B2BOffer.fromJson(Map<String, dynamic> json) => B2BOffer(
    id: json['id'] as String,
    sellerPharmacyId: json['seller_pharmacy_id'] as String,
    productId: json['product_id'] as String?,
    productName: json['product_name'] as String,
    description: json['description'] as String?,
    price: json['price'] as int,
    quantity: json['quantity'] as int,
    unit: json['unit'] as String? ?? 'unité',
    minOrderQuantity: json['min_order_quantity'] as int? ?? 1,
    expiryDate: json['expiry_date'] != null
        ? DateTime.parse(json['expiry_date'] as String)
        : null,
    status: json['status'] as String? ?? 'active',
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    sellerName: json['sellers'] != null
        ? (json['sellers'] as Map<String, dynamic>)['name'] as String?
        : null,
    isNegotiable: json['is_negotiable'] as bool?,
  );

  @override
  List<Object?> get props => [
    id,
    sellerPharmacyId,
    productId,
    productName,
    description,
    price,
    quantity,
    unit,
    minOrderQuantity,
    expiryDate,
    status,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    sellerName,
    isNegotiable,
  ];

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';
      case 'expired':
        return 'Expirée';
      case 'sold_out':
        return 'Épuisée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  bool get isActive =>
      status == 'active' &&
      (expiryDate == null || expiryDate!.isAfter(DateTime.now()));
}
