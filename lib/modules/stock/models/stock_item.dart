import '../../../shared/models/product.dart';
import 'stock_batch.dart';
import 'stock_status.dart';

class StockItem {
  final String id;
  final String pharmacyId;
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
    required this.pharmacyId,
    required this.product,
    required this.batches,
    required this.totalQuantity,
    this.reservedQuantity = 0,
    this.thresholdLow = 20,
    this.thresholdCritical = 5,
    this.defaultLocation,
    this.status = StockStatus.inStock,
  });

  // Audit Module 4 (29/08/2026) : `pharmacy_id` (NOT NULL en base) n'avait
  // aucun équivalent dans ce modèle — StockService lisait donc le stock de
  // TOUTES les officines mélangées, sans jamais filtrer par pharmacie.
  // Au-delà de la fuite (n'importe quel pharmacien voyait/pouvait tenter de
  // gérer le stock d'une autre officine, bloqué seulement par la RLS
  // d'écriture au moment du UPDATE), `getStockItemByProduct` utilisait
  // `.maybeSingle()` sur `product_id` seul : dès qu'une deuxième officine
  // stocke le même produit (cas normal et attendu du modèle multi-officines),
  // cet appel lève une exception (plusieurs lignes retournées). Corrigé en
  // filtrant systématiquement par pharmacy_id (voir StockService).
  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    id: json['id'] as String,
    pharmacyId: json['pharmacy_id'] as String,
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
    String? pharmacyId,
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
      pharmacyId: pharmacyId ?? this.pharmacyId,
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
