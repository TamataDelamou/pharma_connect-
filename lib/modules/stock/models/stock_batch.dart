class StockBatch {
  final String id;
  final String batchNumber;
  final DateTime manufacturingDate;
  final DateTime expiryDate;
  final int quantity;
  final int quantityReserved;
  final double
  purchasePrice; // Prix d'achat unitaire en unité mineure (int mais ici on le garde en int)
  final int purchasePriceInt; // Prix d'achat unitaire en unité mineure
  final DateTime? receivedAt;
  final String? supplierId;
  final String? supplierName;
  final String? location;

  StockBatch({
    required this.id,
    required this.batchNumber,
    required this.manufacturingDate,
    required this.expiryDate,
    required this.quantity,
    this.quantityReserved = 0,
    required this.purchasePriceInt,
    this.receivedAt,
    this.supplierId,
    this.supplierName,
    this.location,
  }) : purchasePrice = purchasePriceInt.toDouble();

  factory StockBatch.fromJson(Map<String, dynamic> json) => StockBatch(
    id: json['id'] as String,
    batchNumber: json['batch_number'] as String,
    manufacturingDate: DateTime.parse(json['manufacturing_date'] as String),
    expiryDate: DateTime.parse(json['expiry_date'] as String),
    quantity: json['quantity'] as int? ?? 0,
    quantityReserved: json['quantity_reserved'] as int? ?? 0,
    purchasePriceInt: json['purchase_price'] as int? ?? 0,
    receivedAt: json['received_at'] != null
        ? DateTime.parse(json['received_at'] as String)
        : null,
    supplierId: json['supplier_id'] as String?,
    supplierName: json['supplier_name'] as String?,
    location: json['location'] as String?,
  );

  Map<String, dynamic> toJson({String? stockItemId}) => {
    'id': id,
    if (stockItemId != null) 'stock_item_id': stockItemId,
    'batch_number': batchNumber,
    'manufacturing_date': manufacturingDate.toIso8601String(),
    'expiry_date': expiryDate.toIso8601String(),
    'quantity': quantity,
    'quantity_reserved': quantityReserved,
    'purchase_price': purchasePriceInt,
    'received_at': receivedAt?.toIso8601String(),
    'supplier_id': supplierId,
    'supplier_name': supplierName,
    'location': location,
  };

  int get availableQuantity => quantity - quantityReserved;
  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isExpiringSoon =>
      expiryDate.isBefore(DateTime.now().add(const Duration(days: 30)));

  StockBatch copyWith({
    String? id,
    String? batchNumber,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    int? quantity,
    int? quantityReserved,
    int? purchasePriceInt,
    DateTime? receivedAt,
    String? supplierId,
    String? supplierName,
    String? location,
  }) {
    return StockBatch(
      id: id ?? this.id,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      quantityReserved: quantityReserved ?? this.quantityReserved,
      purchasePriceInt: purchasePriceInt ?? this.purchasePriceInt,
      receivedAt: receivedAt ?? this.receivedAt,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      location: location ?? this.location,
    );
  }
}
