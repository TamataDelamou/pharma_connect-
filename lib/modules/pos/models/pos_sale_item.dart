import 'package:equatable/equatable.dart';

class POSSaleItem extends Equatable {
  final String id;
  final String saleId;
  final String? productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String? batchId;
  final double discountPercentage;
  final String? notes;
  final DateTime createdAt;
  final String? gsgId;
  final String? gsgOrgId;

  /// C201 / D60 : produit sur ordonnance (avertissement non bloquant) et
  /// confirmation, par le vendeur, d'avoir vu l'ordonnance.
  final bool prescriptionRequired;
  final bool prescriptionChecked;

  const POSSaleItem({
    required this.id,
    required this.saleId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.batchId,
    this.discountPercentage = 0,
    this.notes,
    required this.createdAt,
    this.gsgId,
    this.gsgOrgId,
    this.prescriptionRequired = false,
    this.prescriptionChecked = false,
  });

  POSSaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    int? quantity,
    int? unitPrice,
    int? totalPrice,
    String? batchId,
    double? discountPercentage,
    String? notes,
    DateTime? createdAt,
    String? gsgId,
    String? gsgOrgId,
    bool? prescriptionRequired,
    bool? prescriptionChecked,
  }) {
    return POSSaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      batchId: batchId ?? this.batchId,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      prescriptionRequired: prescriptionRequired ?? this.prescriptionRequired,
      prescriptionChecked: prescriptionChecked ?? this.prescriptionChecked,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sale_id': saleId,
    if (productId != null) 'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    if (batchId != null) 'batch_id': batchId,
    'discount_percentage': discountPercentage,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
    'prescription_required': prescriptionRequired,
    'prescription_checked': prescriptionChecked,
  };

  factory POSSaleItem.fromJson(Map<String, dynamic> json) => POSSaleItem(
    id: json['id'] as String,
    saleId: json['sale_id'] as String,
    productId: json['product_id'] as String?,
    productName: json['product_name'] as String,
    quantity: json['quantity'] as int,
    unitPrice: json['unit_price'] as int,
    totalPrice: json['total_price'] as int,
    batchId: json['batch_id'] as String?,
    discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    prescriptionRequired: json['prescription_required'] as bool? ?? false,
    prescriptionChecked: json['prescription_checked'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [
    id,
    saleId,
    productId,
    productName,
    quantity,
    unitPrice,
    totalPrice,
    batchId,
    discountPercentage,
    notes,
    createdAt,
    gsgId,
    gsgOrgId,
    prescriptionRequired,
    prescriptionChecked,
  ];
}
