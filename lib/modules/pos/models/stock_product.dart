/// C201 : produit du stock de l'officine proposé à l'encaissement, tel que
/// renvoyé par la RPC `pos_search_stock_products`.
class StockProduct {
  final String productId;
  final String name;
  final String? genericName;
  final String? dosage;
  final String? form;

  /// Prix de vente unitaire (`stock_items.unit_price`), en GNF.
  final int unitPrice;

  /// Quantité vendable : lots non périmés, hors quantité réservée.
  final int availableQuantity;

  /// Péremption la plus proche parmi les lots vendables.
  final DateTime? nearestExpiry;

  /// Sur ordonnance (liste, stupéfiant ou psychotrope) : avertissement à la
  /// vente, non bloquant (D60).
  final bool prescriptionRequired;
  final String? regulatoryClass;

  const StockProduct({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.availableQuantity,
    required this.prescriptionRequired,
    this.genericName,
    this.dosage,
    this.form,
    this.nearestExpiry,
    this.regulatoryClass,
  });

  factory StockProduct.fromJson(Map<String, dynamic> json) {
    final expiry = json['nearest_expiry'] as String?;
    return StockProduct(
      productId: json['product_id'] as String,
      name: json['product_name'] as String,
      genericName: json['generic_name'] as String?,
      dosage: json['dosage'] as String?,
      form: json['form'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['available_quantity'] as num?)?.toInt() ?? 0,
      nearestExpiry: expiry == null ? null : DateTime.tryParse(expiry),
      prescriptionRequired: json['prescription_required'] as bool? ?? false,
      regulatoryClass: json['regulatory_class'] as String?,
    );
  }

  /// Libellé affiché dans le panier : nom et dosage.
  String get displayName {
    final d = dosage?.trim();
    return (d == null || d.isEmpty) ? name : '$name $d';
  }

  bool get isAvailable => availableQuantity > 0;
}
