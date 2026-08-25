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
