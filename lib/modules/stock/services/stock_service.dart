import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_item.dart';
import '../models/stock_batch.dart';
import '../models/stock_movement.dart';
import '../models/stock_status.dart';
import '../models/stock_adjustment.dart';
import '../../../core/services/supabase_service.dart';

class StockService {
  SupabaseClient get _client => SupabaseService().client;

  // stock_items.pharmacy_id est NOT NULL en base mais n'a pas d'équivalent
  // dans StockItem (Dart) — voir le commentaire sur StockItem.fromJson.
  // Faute d'une notion de "pharmacie sélectionnée" ailleurs dans l'app, ces
  // requêtes lisent le stock toutes officines confondues.
  static const _stockItemSelect =
      '*, product:products(*, category:categories(name), manufacturer:manufacturers(name)), batches:stock_batches(*)';

  Future<List<StockItem>> getStockItems({String? productId}) async {
    var query = _client.from('stock_items').select(_stockItemSelect);
    if (productId != null) {
      query = query.eq('product_id', productId);
    }
    final rows = await query;
    return rows.map((row) => StockItem.fromJson(row)).toList();
  }

  Future<StockItem?> getStockItem(String id) async {
    final row = await _client
        .from('stock_items')
        .select(_stockItemSelect)
        .eq('id', id)
        .maybeSingle();
    return row != null ? StockItem.fromJson(row) : null;
  }

  Future<StockItem?> getStockItemByProduct(String productId) async {
    final row = await _client
        .from('stock_items')
        .select(_stockItemSelect)
        .eq('product_id', productId)
        .maybeSingle();
    return row != null ? StockItem.fromJson(row) : null;
  }

  Future<List<StockMovement>> getMovements({
    String? stockItemId,
    String? batchId,
    int limit = 50,
  }) async {
    var query = _client.from('stock_movements').select();
    if (stockItemId != null) {
      query = query.eq('stock_item_id', stockItemId);
    }
    if (batchId != null) {
      query = query.eq('batch_id', batchId);
    }
    final rows = await query.order('timestamp', ascending: false).limit(limit);
    return rows.map((row) => StockMovement.fromJson(row)).toList();
  }

  Future<void> _recordMovement({
    required String stockItemId,
    String? batchId,
    required StockMovementType type,
    required int quantity,
    String? userId,
    String? userName,
    String? referenceId,
    String? notes,
  }) async {
    await _client.from('stock_movements').insert(
      StockMovement(
        id: const Uuid().v4(),
        stockItemId: stockItemId,
        batchId: batchId,
        type: type,
        quantity: quantity,
        timestamp: DateTime.now(),
        userId: userId,
        userName: userName,
        referenceId: referenceId,
        notes: notes,
      ).toJson(),
    );
  }

  /// Réserve une quantité d'un produit (pour une commande/prescription).
  /// Logique FEFO : priorise les lots les plus proches de la péremption.
  Future<bool> reserveStock({
    required String productId,
    required int quantity,
    String? referenceId,
    String? userId,
  }) async {
    final stockItem = await getStockItemByProduct(productId);
    if (stockItem == null) return false;
    if (stockItem.availableQuantity < quantity) return false;

    final sortedBatches = List<StockBatch>.from(stockItem.batches)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    int remainingToReserve = quantity;
    for (final batch in sortedBatches) {
      if (remainingToReserve <= 0) break;
      if (batch.availableQuantity <= 0) continue;

      final reserveFromBatch = remainingToReserve > batch.availableQuantity
          ? batch.availableQuantity
          : remainingToReserve;

      await _client
          .from('stock_batches')
          .update({
            'quantity_reserved': batch.quantityReserved + reserveFromBatch,
          })
          .eq('id', batch.id);

      remainingToReserve -= reserveFromBatch;

      await _recordMovement(
        stockItemId: stockItem.id,
        batchId: batch.id,
        type: StockMovementType.reservation,
        quantity: -reserveFromBatch,
        userId: userId,
        referenceId: referenceId,
        notes: 'Réservation pour $referenceId',
      );
    }

    await _client
        .from('stock_items')
        .update({'reserved_quantity': stockItem.reservedQuantity + quantity})
        .eq('id', stockItem.id);

    return true;
  }

  /// Confirme une réservation (transforme en vente).
  Future<bool> confirmReservation({
    required String productId,
    required int quantity,
    String? referenceId,
    String? userId,
  }) async {
    final stockItem = await getStockItemByProduct(productId);
    if (stockItem == null) return false;

    final sortedBatches = List<StockBatch>.from(stockItem.batches)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    int remainingToRemove = quantity;
    for (final batch in sortedBatches) {
      if (remainingToRemove <= 0) break;
      if (batch.availableQuantity <= 0) continue;

      final removeFromBatch = remainingToRemove > batch.availableQuantity
          ? batch.availableQuantity
          : remainingToRemove;

      await _client
          .from('stock_batches')
          .update({
            'quantity': batch.quantity - removeFromBatch,
            'quantity_reserved': batch.quantityReserved - removeFromBatch,
          })
          .eq('id', batch.id);

      remainingToRemove -= removeFromBatch;

      await _recordMovement(
        stockItemId: stockItem.id,
        batchId: batch.id,
        type: StockMovementType.sale,
        quantity: -removeFromBatch,
        userId: userId,
        referenceId: referenceId,
        notes: 'Vente confirmée pour $referenceId',
      );
    }

    final newTotal = stockItem.totalQuantity - quantity;
    final newReserved = stockItem.reservedQuantity - quantity;
    await _client
        .from('stock_items')
        .update({
          'total_quantity': newTotal,
          'reserved_quantity': newReserved,
          'status': _computeStockStatus(
            newTotal,
            stockItem.thresholdLow,
            stockItem.thresholdCritical,
          ).name,
        })
        .eq('id', stockItem.id);

    return true;
  }

  /// Annule une réservation — libère les lots ayant la plus grande quantité
  /// réservée en premier.
  Future<bool> cancelReservation({
    required String productId,
    required int quantity,
    String? referenceId,
  }) async {
    final stockItem = await getStockItemByProduct(productId);
    if (stockItem == null) return false;

    final sortedBatches = List<StockBatch>.from(stockItem.batches)
      ..sort((a, b) => b.quantityReserved.compareTo(a.quantityReserved));

    int remainingToRelease = quantity;
    for (final batch in sortedBatches) {
      if (remainingToRelease <= 0) break;
      if (batch.quantityReserved <= 0) continue;

      final releaseFromBatch = remainingToRelease > batch.quantityReserved
          ? batch.quantityReserved
          : remainingToRelease;

      await _client
          .from('stock_batches')
          .update({
            'quantity_reserved': batch.quantityReserved - releaseFromBatch,
          })
          .eq('id', batch.id);

      remainingToRelease -= releaseFromBatch;

      await _recordMovement(
        stockItemId: stockItem.id,
        batchId: batch.id,
        type: StockMovementType.unreservation,
        quantity: releaseFromBatch,
        referenceId: referenceId,
        notes: 'Annulation réservation pour $referenceId',
      );
    }

    await _client
        .from('stock_items')
        .update({'reserved_quantity': stockItem.reservedQuantity - quantity})
        .eq('id', stockItem.id);

    return true;
  }

  StockStatus _computeStockStatus(
    int quantity,
    int thresholdLow,
    int thresholdCritical,
  ) {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity <= thresholdCritical) return StockStatus.critical;
    if (quantity <= thresholdLow) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  // ==================== AJUSTEMENTS ====================

  Future<bool> adjustStock({
    required String productId,
    required int quantity, // positif = ajout, négatif = retrait
    required AdjustmentReason reason,
    String? batchId,
    String? userId,
    String? userName,
    String? notes,
  }) async {
    final stockItem = await getStockItemByProduct(productId);
    if (stockItem == null) return false;

    final newTotal = stockItem.totalQuantity + quantity;
    await _client
        .from('stock_items')
        .update({
          'total_quantity': newTotal,
          'status': _computeStockStatus(
            newTotal,
            stockItem.thresholdLow,
            stockItem.thresholdCritical,
          ).name,
        })
        .eq('id', stockItem.id);

    if (batchId != null && quantity > 0) {
      final batchIndex = stockItem.batches.indexWhere((b) => b.id == batchId);
      if (batchIndex != -1) {
        final batch = stockItem.batches[batchIndex];
        await _client
            .from('stock_batches')
            .update({'quantity': batch.quantity + quantity})
            .eq('id', batchId);
      }
    }

    await _client.from('stock_adjustments').insert(
      StockAdjustment(
        id: const Uuid().v4(),
        stockItemId: stockItem.id,
        batchId: batchId,
        reason: reason,
        quantity: quantity,
        userId: userId,
        userName: userName,
        notes: notes ?? reason.label,
        timestamp: DateTime.now(),
      ).toJson(),
    );

    await _recordMovement(
      stockItemId: stockItem.id,
      batchId: batchId,
      type: StockMovementType.adjustment,
      quantity: quantity,
      userId: userId,
      userName: userName,
      notes: notes ?? reason.label,
    );

    return true;
  }

  // ==================== TRANSFERTS ====================

  Future<bool> transferStock({
    required String productId,
    required int quantity,
    required String fromPharmacyId,
    required String toPharmacyId,
    String? userId,
    String? notes,
  }) async {
    // Dans un vrai système multi-officines, ceci ferait deux écritures (une
    // par pharmacy_id). Le modèle actuel ne scope pas stock_items par
    // officine côté Dart (voir StockItem.fromJson) : on retire simplement du
    // stock local, comme le faisait le mock.
    final stockItem = await getStockItemByProduct(productId);
    if (stockItem == null) return false;
    if (stockItem.availableQuantity < quantity) return false;

    final newTotal = stockItem.totalQuantity - quantity;
    await _client
        .from('stock_items')
        .update({
          'total_quantity': newTotal,
          'status': _computeStockStatus(
            newTotal,
            stockItem.thresholdLow,
            stockItem.thresholdCritical,
          ).name,
        })
        .eq('id', stockItem.id);

    await _recordMovement(
      stockItemId: stockItem.id,
      type: StockMovementType.transfer,
      quantity: -quantity,
      userId: userId,
      notes: notes ?? 'Transfert vers $toPharmacyId depuis $fromPharmacyId',
    );

    return true;
  }

  // ==================== ALERTES ====================

  Future<List<StockItem>> getLowStockItems() async {
    final items = await getStockItems();
    return items.where((i) => i.isLowStock || i.isCriticalStock).toList();
  }

  Future<List<StockItem>> getOutOfStockItems() async {
    final items = await getStockItems();
    return items.where((i) => i.isOutOfStock).toList();
  }

  Future<List<StockBatch>> getExpiringBatches({int daysThreshold = 30}) async {
    final threshold = DateTime.now().add(Duration(days: daysThreshold));
    final rows = await _client
        .from('stock_batches')
        .select()
        .lt('expiry_date', threshold.toIso8601String());
    final batches = rows.map((row) => StockBatch.fromJson(row)).toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return batches.where((b) => !b.isExpired).toList();
  }

  // ==================== RECHERCHE AVANCÉE ====================
  // Filtré côté client après lecture complète plutôt que via des filtres
  // PostgREST imbriqués sur stock_batches (risque de changer la sémantique
  // de la jointure sans base réelle pour le vérifier — même choix que
  // CatalogService pour la recherche par nom de fabricant).

  Future<List<StockItem>> searchStock({
    String? query,
    String? batchNumber,
    String? supplierId,
    DateTime? expiryBefore,
    DateTime? expiryAfter,
    StockStatus? status,
  }) async {
    var items = await getStockItems();

    if (query != null && query.isNotEmpty) {
      final lower = query.toLowerCase();
      items = items
          .where(
            (item) =>
                item.product.name.toLowerCase().contains(lower) ||
                item.product.genericName.toLowerCase().contains(lower) ||
                item.product.manufacturer.toLowerCase().contains(lower),
          )
          .toList();
    }

    if (batchNumber != null && batchNumber.isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.batches.any((b) => b.batchNumber.contains(batchNumber)),
          )
          .toList();
    }

    if (supplierId != null) {
      items = items
          .where((item) => item.batches.any((b) => b.supplierId == supplierId))
          .toList();
    }

    if (expiryBefore != null) {
      items = items
          .where(
            (item) =>
                item.batches.any((b) => b.expiryDate.isBefore(expiryBefore)),
          )
          .toList();
    }

    if (expiryAfter != null) {
      items = items
          .where(
            (item) =>
                item.batches.any((b) => b.expiryDate.isAfter(expiryAfter)),
          )
          .toList();
    }

    if (status != null) {
      items = items.where((item) => item.status == status).toList();
    }

    return items;
  }
}
