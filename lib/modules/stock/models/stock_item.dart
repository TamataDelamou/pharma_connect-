import '../../../shared/models/product.dart';
import 'stock_batch.dart';
import 'stock_status.dart';

class StockItem {
  final String id;
  final Product product;
  final List<StockBatch> batches;
  final int totalQuantity;
  final int reservedQuantity;
  final int thresholdLow;
  final int thresholdCritical;
  final String? defaultLocation;
  final StockStatus status;

  StockItem({
    required this.id,
    required this.product,
    required this.batches,
    required this.totalQuantity,
    this.reservedQuantity = 0,
    this.thresholdLow = 20,
    this.thresholdCritical = 5,
    this.defaultLocation,
    this.status = StockStatus.inStock,
  });

  // stock_items.pharmacy_id (NOT NULL en base) n'a pas d'équivalent ici : le
  // modèle Dart actuel ne porte qu'un defaultLocation texte libre. Tant que
  // l'app n'a pas de notion de "pharmacie sélectionnée", le service lit
  // toutes les officines sans filtrer par pharmacy_id (voir StockService).
  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    id: json['id'] as String,
    product: Product.fromJson(json['product'] as Map<String, dynamic>),
    batches: (json['batches'] as List<dynamic>? ?? [])
        .map((b) => StockBatch.fromJson(b as Map<String, dynamic>))
        .toList(),
    totalQuantity: json['total_quantity'] as int? ?? 0,
    reservedQuantity: json['reserved_quantity'] as int? ?? 0,
    thresholdLow: json['threshold_low'] as int? ?? 20,
    thresholdCritical: json['threshold_critical'] as int? ?? 5,
    defaultLocation: json['default_location'] as String?,
    status: StockStatus.values.byName(json['status'] as String),
  );

  int get availableQuantity => totalQuantity - reservedQuantity;
  bool get isLowStock =>
      availableQuantity <= thresholdLow &&
      availableQuantity > thresholdCritical;
  bool get isCriticalStock => availableQuantity <= thresholdCritical;
  bool get isOutOfStock => availableQuantity <= 0;

  StockItem copyWith({
    String? id,
    Product? product,
    List<StockBatch>? batches,
    int? totalQuantity,
    int? reservedQuantity,
    int? thresholdLow,
    int? thresholdCritical,
    String? defaultLocation,
    StockStatus? status,
  }) {
    return StockItem(
      id: id ?? this.id,
      product: product ?? this.product,
      batches: batches ?? this.batches,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      thresholdLow: thresholdLow ?? this.thresholdLow,
      thresholdCritical: thresholdCritical ?? this.thresholdCritical,
      defaultLocation: defaultLocation ?? this.defaultLocation,
      status: status ?? this.status,
    );
  }
}
