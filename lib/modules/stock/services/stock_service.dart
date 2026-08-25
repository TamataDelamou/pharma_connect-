import 'dart:math';
import '../../../shared/models/product.dart';
import '../models/stock_item.dart';
import '../models/stock_batch.dart';
import '../models/stock_movement.dart';
import '../models/stock_status.dart';
import '../models/stock_adjustment.dart';

class StockService {
  static final Random _random = Random();

  // ==================== DONNÉES MOCKÉES ====================

  // Référence aux produits (simulés)
  static final List<Product> _mockProducts = [
    Product(
      id: 'p1',
      name: 'Doliprane 1000mg',
      genericName: 'Paracétamol',
      dosage: '1000 mg',
      form: 'Comprimé',
      category: 'Antalgique',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Sanofi',
      isPrescriptionRequired: false,
    ),
    Product(
      id: 'p2',
      name: 'Amoxicilline 500mg',
      genericName: 'Amoxicilline',
      dosage: '500 mg',
      form: 'Gélule',
      category: 'Antibiotique',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'Biogaran',
      isPrescriptionRequired: true,
    ),
    Product(
      id: 'p3',
      name: 'Ventoline 100µg',
      genericName: 'Salbutamol',
      dosage: '100 µg',
      form: 'Aérosol',
      category: 'Respiratoire',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'GSK',
      isPrescriptionRequired: true,
    ),
    Product(
      id: 'p4',
      name: 'Spasfon 80mg',
      genericName: 'Phloroglucinol',
      dosage: '80 mg',
      form: 'Comprimé',
      category: 'Digestif',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Teva',
      isPrescriptionRequired: false,
    ),
    Product(
      id: 'p5',
      name: 'Crestor 10mg',
      genericName: 'Rosuvastatine',
      dosage: '10 mg',
      form: 'Comprimé',
      category: 'Cardiologie',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'AstraZeneca',
      isPrescriptionRequired: true,
    ),
  ];

  // Stock initial
  static final List<StockItem> _stockItems = [
    StockItem(
      id: 'stock_001',
      product: _mockProducts[0], // Doliprane
      batches: [
        StockBatch(
          id: 'batch_001',
          batchNumber: 'B2024-001',
          manufacturingDate: DateTime(2024, 1, 15),
          expiryDate: DateTime(2026, 1, 15),
          quantity: 150,
          purchasePriceInt: 2000,
          receivedAt: DateTime(2024, 1, 20),
          supplierName: 'Sanofi',
          location: 'A-12',
        ),
        StockBatch(
          id: 'batch_002',
          batchNumber: 'B2024-002',
          manufacturingDate: DateTime(2024, 3, 10),
          expiryDate: DateTime(2026, 3, 10),
          quantity: 80,
          purchasePriceInt: 2100,
          receivedAt: DateTime(2024, 3, 15),
          supplierName: 'Sanofi',
          location: 'A-13',
        ),
      ],
      totalQuantity: 230,
      thresholdLow: 20,
      thresholdCritical: 5,
      defaultLocation: 'A-12',
    ),
    StockItem(
      id: 'stock_002',
      product: _mockProducts[1], // Amoxicilline
      batches: [
        StockBatch(
          id: 'batch_003',
          batchNumber: 'B2024-003',
          manufacturingDate: DateTime(2024, 2, 1),
          expiryDate: DateTime(2025, 2, 1),
          quantity: 45,
          purchasePriceInt: 3500,
          receivedAt: DateTime(2024, 2, 5),
          supplierName: 'Biogaran',
          location: 'B-05',
        ),
      ],
      totalQuantity: 45,
      thresholdLow: 15,
      thresholdCritical: 3,
      defaultLocation: 'B-05',
    ),
    StockItem(
      id: 'stock_003',
      product: _mockProducts[2], // Ventoline
      batches: [
        StockBatch(
          id: 'batch_004',
          batchNumber: 'B2024-004',
          manufacturingDate: DateTime(2024, 4, 1),
          expiryDate: DateTime(2026, 4, 1),
          quantity: 12,
          purchasePriceInt: 7500,
          receivedAt: DateTime(2024, 4, 10),
          supplierName: 'GSK',
          location: 'C-02',
        ),
      ],
      totalQuantity: 12,
      thresholdLow: 10,
      thresholdCritical: 3,
      defaultLocation: 'C-02',
      status: StockStatus.lowStock,
    ),
    StockItem(
      id: 'stock_004',
      product: _mockProducts[3], // Spasfon
      batches: [
        StockBatch(
          id: 'batch_005',
          batchNumber: 'B2024-005',
          manufacturingDate: DateTime(2024, 5, 1),
          expiryDate: DateTime(2025, 12, 1),
          quantity: 2,
          purchasePriceInt: 2800,
          receivedAt: DateTime(2024, 5, 5),
          supplierName: 'Teva',
          location: 'D-08',
        ),
      ],
      totalQuantity: 2,
      thresholdLow: 10,
      thresholdCritical: 3,
      defaultLocation: 'D-08',
      status: StockStatus.critical,
    ),
    StockItem(
      id: 'stock_005',
      product: _mockProducts[4], // Crestor
      batches: [],
      totalQuantity: 0,
      thresholdLow: 5,
      thresholdCritical: 2,
      defaultLocation: 'E-03',
      status: StockStatus.outOfStock,
    ),
  ];

  // Historique des mouvements
  static final List<StockMovement> _movements = [
    StockMovement(
      id: 'mov_001',
      stockItemId: 'stock_001',
      batchId: 'batch_001',
      type: StockMovementType.purchase,
      quantity: 150,
      timestamp: DateTime(2024, 1, 20),
      userName: 'Admin',
      notes: 'Commande initiale',
    ),
    StockMovement(
      id: 'mov_002',
      stockItemId: 'stock_001',
      batchId: 'batch_002',
      type: StockMovementType.purchase,
      quantity: 80,
      timestamp: DateTime(2024, 3, 15),
      userName: 'Admin',
      notes: 'Réapprovisionnement',
    ),
    StockMovement(
      id: 'mov_003',
      stockItemId: 'stock_001',
      batchId: 'batch_001',
      type: StockMovementType.sale,
      quantity: -30,
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      userName: 'Pharmacien',
      referenceId: 'rx_001',
      notes: 'Ordonnance patient',
    ),
    StockMovement(
      id: 'mov_004',
      stockItemId: 'stock_002',
      batchId: 'batch_003',
      type: StockMovementType.purchase,
      quantity: 45,
      timestamp: DateTime(2024, 2, 5),
      userName: 'Admin',
      notes: 'Commande initiale',
    ),
    StockMovement(
      id: 'mov_005',
      stockItemId: 'stock_003',
      batchId: 'batch_004',
      type: StockMovementType.purchase,
      quantity: 12,
      timestamp: DateTime(2024, 4, 10),
      userName: 'Admin',
      notes: 'Commande initiale',
    ),
    StockMovement(
      id: 'mov_006',
      stockItemId: 'stock_004',
      batchId: 'batch_005',
      type: StockMovementType.purchase,
      quantity: 2,
      timestamp: DateTime(2024, 5, 5),
      userName: 'Admin',
      notes: 'Commande initiale',
    ),
  ];

  // ==================== MÉTHODES ====================

  Future<List<StockItem>> getStockItems({String? productId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (productId != null) {
      return _stockItems.where((item) => item.product.id == productId).toList();
    }
    return _stockItems;
  }

  Future<StockItem?> getStockItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _stockItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<StockItem?> getStockItemByProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _stockItems.firstWhere((item) => item.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  Future<List<StockMovement>> getMovements({
    String? stockItemId,
    String? batchId,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var list = _movements;
    if (stockItemId != null) {
      list = list.where((m) => m.stockItemId == stockItemId).toList();
    }
    if (batchId != null) {
      list = list.where((m) => m.batchId == batchId).toList();
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(limit).toList();
  }

  /// Réserve une quantité d'un produit (pour une commande/prescription)
  /// Utilise la logique FEFO : priorise les lots les plus proches de la péremption
  Future<bool> reserveStock({
    required String productId,
    required int quantity,
    String? referenceId,
    String? userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final stockItem = await getStockItemByProduct(productId);
    if (stockItem == null) return false;
    if (stockItem.availableQuantity < quantity) return false;

    // Logique FEFO : trier les lots par date de péremption
    final sortedBatches = List<StockBatch>.from(stockItem.batches)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    int remainingToReserve = quantity;
    for (final batch in sortedBatches) {
      if (remainingToReserve <= 0) break;
      if (batch.availableQuantity <= 0) continue;

      final reserveFromBatch = remainingToReserve > batch.availableQuantity
          ? batch.availableQuantity
          : remainingToReserve;

      // Mettre à jour le lot
      final batchIndex = stockItem.batches.indexOf(batch);
      stockItem.batches[batchIndex] = batch.copyWith(
        quantityReserved: batch.quantityReserved + reserveFromBatch,
      );

      remainingToReserve -= reserveFromBatch;

      // Ajouter un mouvement de réservation
      _movements.add(
        StockMovement(
          id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
          stockItemId: stockItem.id,
          batchId: batch.id,
          type: StockMovementType.reservation,
          quantity: -reserveFromBatch,
          timestamp: DateTime.now(),
          userId: userId,
          referenceId: referenceId,
          notes: 'Réservation pour $referenceId',
        ),
      );
    }

    // Mettre à jour le stock total réservé
    final itemIndex = _stockItems.indexWhere((item) => item.id == stockItem.id);
    if (itemIndex != -1) {
      _stockItems[itemIndex] = stockItem.copyWith(
        reservedQuantity: stockItem.reservedQuantity + quantity,
      );
    }

    return true;
  }

  /// Confirme une réservation (transforme en vente)
  Future<bool> confirmReservation({
    required String productId,
    required int quantity,
    String? referenceId,
    String? userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final stockItem = await getStockItemByProduct(productId);
    if (stockItem == null) return false;

    // Retirer des lots en priorisant FEFO (même logique)
    final sortedBatches = List<StockBatch>.from(stockItem.batches)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    int remainingToRemove = quantity;
    for (final batch in sortedBatches) {
      if (remainingToRemove <= 0) break;
      if (batch.availableQuantity <= 0) continue;

      final removeFromBatch = remainingToRemove > batch.availableQuantity
          ? batch.availableQuantity
          : remainingToRemove;

      final batchIndex = stockItem.batches.indexOf(batch);
      stockItem.batches[batchIndex] = batch.copyWith(
        quantity: batch.quantity - removeFromBatch,
        quantityReserved: batch.quantityReserved - removeFromBatch,
      );

      remainingToRemove -= removeFromBatch;

      _movements.add(
        StockMovement(
          id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
          stockItemId: stockItem.id,
          batchId: batch.id,
          type: StockMovementType.sale,
          quantity: -removeFromBatch,
          timestamp: DateTime.now(),
          userId: userId,
          referenceId: referenceId,
          notes: 'Vente confirmée pour $referenceId',
        ),
      );
    }

    final itemIndex = _stockItems.indexWhere((item) => item.id == stockItem.id);
    if (itemIndex != -1) {
      final newTotal = stockItem.totalQuantity - quantity;
      final newReserved = stockItem.reservedQuantity - quantity;
      _stockItems[itemIndex] = stockItem.copyWith(
        totalQuantity: newTotal,
        reservedQuantity: newReserved,
        status: _computeStockStatus(
          newTotal,
          stockItem.thresholdLow,
          stockItem.thresholdCritical,
        ),
      );
    }

    return true;
  }

  /// Annule une réservation
  Future<bool> cancelReservation({
    required String productId,
    required int quantity,
    String? referenceId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final stockItem = await getStockItemByProduct(productId);
    if (stockItem == null) return false;

    // Libérer les réservations (FIFO inverse : on libère les derniers réservés)
    final sortedBatches = List<StockBatch>.from(stockItem.batches)
      ..sort((a, b) => a.quantityReserved.compareTo(b.quantityReserved))
      ..reversed;

    int remainingToRelease = quantity;
    for (final batch in sortedBatches) {
      if (remainingToRelease <= 0) break;
      if (batch.quantityReserved <= 0) continue;

      final releaseFromBatch = remainingToRelease > batch.quantityReserved
          ? batch.quantityReserved
          : remainingToRelease;

      final batchIndex = stockItem.batches.indexOf(batch);
      stockItem.batches[batchIndex] = batch.copyWith(
        quantityReserved: batch.quantityReserved - releaseFromBatch,
      );

      remainingToRelease -= releaseFromBatch;

      _movements.add(
        StockMovement(
          id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
          stockItemId: stockItem.id,
          batchId: batch.id,
          type: StockMovementType.unreservation,
          quantity: releaseFromBatch,
          timestamp: DateTime.now(),
          referenceId: referenceId,
          notes: 'Annulation réservation pour $referenceId',
        ),
      );
    }

    final itemIndex = _stockItems.indexWhere((item) => item.id == stockItem.id);
    if (itemIndex != -1) {
      _stockItems[itemIndex] = stockItem.copyWith(
        reservedQuantity: stockItem.reservedQuantity - quantity,
      );
    }

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
  // Ajouter ces méthodes à la fin du service existant

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
    await Future.delayed(const Duration(milliseconds: 300));
    final stockItem = await getStockItemByProduct(productId);
    if (stockItem == null) return false;

    final adjustedItem = stockItem.copyWith(
      totalQuantity: stockItem.totalQuantity + quantity,
      status: _computeStockStatus(
        stockItem.totalQuantity + quantity,
        stockItem.thresholdLow,
        stockItem.thresholdCritical,
      ),
    );

    // Mettre à jour le lot si spécifié
    if (batchId != null && quantity > 0) {
      final batchIndex = adjustedItem.batches.indexWhere(
        (b) => b.id == batchId,
      );
      if (batchIndex != -1) {
        adjustedItem.batches[batchIndex] = adjustedItem.batches[batchIndex]
            .copyWith(
              quantity: adjustedItem.batches[batchIndex].quantity + quantity,
            );
      }
    }

    final itemIndex = _stockItems.indexWhere((item) => item.id == stockItem.id);
    if (itemIndex != -1) {
      _stockItems[itemIndex] = adjustedItem;
    }

    _movements.add(
      StockMovement(
        id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
        stockItemId: stockItem.id,
        batchId: batchId,
        type: quantity > 0
            ? StockMovementType.adjustment
            : StockMovementType.adjustment,
        quantity: quantity,
        timestamp: DateTime.now(),
        userId: userId,
        userName: userName,
        notes: notes ?? reason.label,
      ),
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
    await Future.delayed(const Duration(milliseconds: 500));
    // Dans un vrai système, on ferait un appel API entre pharmacies
    // Ici on simule en retirant du stock local et en ajoutant une note

    final stockItem = await getStockItemByProduct(productId);
    if (stockItem == null) return false;
    if (stockItem.availableQuantity < quantity) return false;

    final adjustedItem = stockItem.copyWith(
      totalQuantity: stockItem.totalQuantity - quantity,
      status: _computeStockStatus(
        stockItem.totalQuantity - quantity,
        stockItem.thresholdLow,
        stockItem.thresholdCritical,
      ),
    );

    final itemIndex = _stockItems.indexWhere((item) => item.id == stockItem.id);
    if (itemIndex != -1) {
      _stockItems[itemIndex] = adjustedItem;
    }

    _movements.add(
      StockMovement(
        id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
        stockItemId: stockItem.id,
        type: StockMovementType.transfer,
        quantity: -quantity,
        timestamp: DateTime.now(),
        userId: userId,
        notes: notes ?? 'Transfert vers $toPharmacyId depuis $fromPharmacyId',
      ),
    );

    return true;
  }

  // ==================== ALERTES ====================

  Future<List<StockItem>> getLowStockItems() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _stockItems
        .where((item) => item.isLowStock || item.isCriticalStock)
        .toList();
  }

  Future<List<StockItem>> getOutOfStockItems() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _stockItems.where((item) => item.isOutOfStock).toList();
  }

  Future<List<StockBatch>> getExpiringBatches({int daysThreshold = 30}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final allBatches = <StockBatch>[];
    for (final item in _stockItems) {
      allBatches.addAll(item.batches);
    }
    final threshold = DateTime.now().add(Duration(days: daysThreshold));
    return allBatches
        .where(
          (batch) => !batch.isExpired && batch.expiryDate.isBefore(threshold),
        )
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  // ==================== RECHERCHE AVANCÉE ====================

  Future<List<StockItem>> searchStock({
    String? query,
    String? batchNumber,
    String? supplierId,
    DateTime? expiryBefore,
    DateTime? expiryAfter,
    StockStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var items = List<StockItem>.from(_stockItems);

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
