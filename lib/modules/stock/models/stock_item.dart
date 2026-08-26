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
