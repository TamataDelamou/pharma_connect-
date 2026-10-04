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

  static const _stockItemSelect =
      '*, product:products(*, category:categories(name), manufacturer:manufacturers(name)), batches:stock_batches(*)';

  /// Audit Module 4 (29/08/2026) : version brute (JSON non désérialisé) de
  /// getStockItems, utilisée directement par StockProvider pour alimenter le
  /// cache hors-ligne (StockItem.fromJson perdrait des champs bruts utiles
  /// à la ré-écriture locale). getStockItems ci-dessous délègue à celle-ci.
  Future<List<Map<String, dynamic>>> getStockItemsRaw({
    String? pharmacyId,
    String? productId,
  }) async {
    var query = _client.from('stock_items').select(_stockItemSelect);
    // RG multi-officines : sans ce filtre, le stock de TOUTES les officines
    // était mélangé dans une même liste (voir StockItem.fromJson) — un
    // pharmacien voyait/pouvait tenter d'ajuster le stock d'une officine
    // qui n'est pas la sienne, bloqué seulement au moment de l'écriture par
    // la RLS (is_pharmacy_staff). pharmacyId reste optionnel pour un futur
    // usage back-office (is_gsg_admin) qui aurait légitimement besoin d'une
    // vue toutes officines.
    if (pharmacyId != null) {
      query = query.eq('pharmacy_id', pharmacyId);
    }
    if (productId != null) {
      query = query.eq('product_id', productId);
    }
    return await query;
  }

  Future<List<StockItem>> getStockItems({
    String? pharmacyId,
    String? productId,
  }) async {
    final rows = await getStockItemsRaw(
      pharmacyId: pharmacyId,
      productId: productId,
    );
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

  /// `pharmacyId` est requis : `product_id` seul n'identifie pas une ligne
  /// unique dès que plusieurs officines stockent le même produit (c'est le
  /// cas normal du modèle multi-officines, contrainte unique sur
  /// (pharmacy_id, product_id)) — sans ce filtre, `.maybeSingle()` levait
  /// une exception dès qu'une deuxième officine stockait le produit
  /// recherché (audit Module 4, 29/08/2026).
  Future<StockItem?> getStockItemByProduct(
    String productId, {
    required String pharmacyId,
  }) async {
    final row = await _client
        .from('stock_items')
        .select(_stockItemSelect)
        .eq('product_id', productId)
        .eq('pharmacy_id', pharmacyId)
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
    await _client
        .from('stock_movements')
        .insert(
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

  /// C242 : quantité vendable d'un produit dans une officine active (lots
  /// non périmés, non rappelés, hors réservé), calculée par le serveur
  /// (`patient_stock_availability`). 0 si le produit n'y est pas en stock.
  Future<int> getSellableQuantity({
    required String productId,
    required String pharmacyId,
  }) async {
    final List<dynamic> rows = await _client.rpc(
      'patient_stock_availability',
      params: {
        'p_product_ids': [productId],
        'p_pharmacy_id': pharmacyId,
      },
    );
    if (rows.isEmpty) return 0;
    return rows.first['available_quantity'] as int? ?? 0;
  }

  /// C242 : vrai si au moins une officine active a une quantité vendable
  /// d'un des produits donnés.
  Future<bool> isAnySellable(List<String> productIds) async {
    if (productIds.isEmpty) return false;
    final List<dynamic> rows = await _client.rpc(
      'patient_stock_availability',
      params: {'p_product_ids': productIds},
    );
    return rows.any((row) => (row['available_quantity'] as int? ?? 0) > 0);
  }

  // C243 : reserveStock, confirmReservation et cancelReservation supprimées.
  // La réservation est faite par le serveur (fonctions `reservation_*`), qui
  // retient, libère et vend les boîtes dans une seule transaction ; plus
  // aucune écriture de stock pour une réservation depuis l'application.

  /// Rendu public + static (audit Module 4, 29/08/2026) : réutilisé par
  /// StockProvider pour calculer un statut cohérent lors d'un ajustement mis
  /// en file d'attente hors-ligne, sans dupliquer cette logique.
  static StockStatus computeStockStatus(
    int quantity,
    int thresholdLow,
    int thresholdCritical,
  ) {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity <= thresholdCritical) return StockStatus.critical;
    if (quantity <= thresholdLow) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  // ==================== SEUILS (Module 10 — ALR, arbitrage D15) ====================
  //
  // Écran « Paramétrage des seuils par produit » (cahier ALR, manquant avant
  // cet audit — voir registre D15). Les colonnes existaient déjà et étaient
  // déjà en écriture pour le staff d'officine (policy stock_items_write_staff,
  // Module 4) ; seule cette méthode et l'écran qui l'appelle manquaient.
  // Recalcule aussi `status` immédiatement (computeStockStatus) : changer un
  // seuil peut, à quantité inchangée, faire basculer un article en/hors
  // alerte sans qu'aucun mouvement de stock n'ait eu lieu.

  Future<bool> updateThresholds({
    required String stockItemId,
    required int thresholdLow,
    required int thresholdCritical,
  }) async {
    if (thresholdLow < 0 || thresholdCritical < 0) return false;
    if (thresholdCritical > thresholdLow) return false;

    final item = await getStockItem(stockItemId);
    if (item == null) return false;

    await _client
        .from('stock_items')
        .update({
          'threshold_low': thresholdLow,
          'threshold_critical': thresholdCritical,
          'status': computeStockStatus(
            item.availableQuantity,
            thresholdLow,
            thresholdCritical,
          ).name,
        })
        .eq('id', stockItemId);

    return true;
  }

  // ==================== AJUSTEMENTS ====================

  Future<bool> adjustStock({
    required String productId,
    required String pharmacyId,
    required int quantity, // positif = ajout, négatif = retrait
    required AdjustmentReason reason,
    String? batchId,
    String? userId,
    String? userName,
    String? notes,
  }) async {
    final stockItem = await getStockItemByProduct(
      productId,
      pharmacyId: pharmacyId,
    );
    if (stockItem == null) return false;

    final newTotal = stockItem.totalQuantity + quantity;
    await _client
        .from('stock_items')
        .update({
          'total_quantity': newTotal,
          'status': computeStockStatus(
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

    await _client
        .from('stock_adjustments')
        .insert(
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
    // Audit Module 4 (29/08/2026) : `fromPharmacyId`/`toPharmacyId` étaient
    // déjà des paramètres de cette fonction mais n'étaient jamais utilisés —
    // `getStockItemByProduct(productId)` sans filtre officine pouvait
    // décrémenter le stock d'une AUTRE pharmacie que `fromPharmacyId`, et
    // aucune écriture n'était faite côté `toPharmacyId` : la quantité
    // transférée disparaissait purement et simplement (aucune ligne
    // stock_items n'était créditée nulle part). Corrigé : décrémente
    // uniquement le stock de fromPharmacyId, et crédite (ou crée) la ligne
    // stock_items de toPharmacyId pour ce même produit.
    final sourceItem = await getStockItemByProduct(
      productId,
      pharmacyId: fromPharmacyId,
    );
    if (sourceItem == null) return false;
    if (sourceItem.availableQuantity < quantity) return false;

    final newSourceTotal = sourceItem.totalQuantity - quantity;
    await _client
        .from('stock_items')
        .update({
          'total_quantity': newSourceTotal,
          'status': computeStockStatus(
            newSourceTotal,
            sourceItem.thresholdLow,
            sourceItem.thresholdCritical,
          ).name,
        })
        .eq('id', sourceItem.id);

    await _recordMovement(
      stockItemId: sourceItem.id,
      type: StockMovementType.transfer,
      quantity: -quantity,
      userId: userId,
      notes: notes ?? 'Transfert vers $toPharmacyId depuis $fromPharmacyId',
    );

    final destItem = await getStockItemByProduct(
      productId,
      pharmacyId: toPharmacyId,
    );
    if (destItem != null) {
      final newDestTotal = destItem.totalQuantity + quantity;
      await _client
          .from('stock_items')
          .update({
            'total_quantity': newDestTotal,
            'status': computeStockStatus(
              newDestTotal,
              destItem.thresholdLow,
              destItem.thresholdCritical,
            ).name,
          })
          .eq('id', destItem.id);
      await _recordMovement(
        stockItemId: destItem.id,
        type: StockMovementType.transfer,
        quantity: quantity,
        userId: userId,
        notes: notes ?? 'Transfert reçu de $fromPharmacyId',
      );
    } else {
      // Aucune ligne stock_items n'existe encore pour ce produit dans
      // l'officine destinataire : on en crée une (même seuils par défaut
      // que la migration stock.sql). La RLS d'écriture (is_pharmacy_staff)
      // s'applique normalement à cet insert comme à n'importe quel autre.
      final inserted = await _client
          .from('stock_items')
          .insert({
            'pharmacy_id': toPharmacyId,
            'product_id': productId,
            'total_quantity': quantity,
            'status': computeStockStatus(quantity, 20, 5).name,
          })
          .select()
          .single();
      await _recordMovement(
        stockItemId: inserted['id'] as String,
        type: StockMovementType.transfer,
        quantity: quantity,
        userId: userId,
        notes: notes ?? 'Transfert reçu de $fromPharmacyId',
      );
    }

    return true;
  }

  // ==================== ALERTES ====================

  Future<List<StockItem>> getLowStockItems({String? pharmacyId}) async {
    final items = await getStockItems(pharmacyId: pharmacyId);
    return items.where((i) => i.isLowStock || i.isCriticalStock).toList();
  }

  Future<List<StockItem>> getOutOfStockItems({String? pharmacyId}) async {
    final items = await getStockItems(pharmacyId: pharmacyId);
    return items.where((i) => i.isOutOfStock).toList();
  }

  Future<List<StockBatch>> getExpiringBatches({
    String? pharmacyId,
    int daysThreshold = 30,
  }) async {
    final threshold = DateTime.now().add(Duration(days: daysThreshold));
    // !inner nécessaire pour que le filtre sur stock_item.pharmacy_id
    // s'applique réellement (même piège PostgREST déjà documenté en Module 2
    // : un embed simple sans !inner ne filtre pas, il nullifie l'objet).
    var query = _client
        .from('stock_batches')
        .select(
          pharmacyId != null
              ? '*, stock_item:stock_items!inner(pharmacy_id)'
              : '*',
        )
        .lt('expiry_date', threshold.toIso8601String());
    if (pharmacyId != null) {
      query = query.eq('stock_item.pharmacy_id', pharmacyId);
    }
    final rows = await query;
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
    String? pharmacyId,
    String? query,
    String? batchNumber,
    String? supplierId,
    DateTime? expiryBefore,
    DateTime? expiryAfter,
    StockStatus? status,
  }) async {
    var items = await getStockItems(pharmacyId: pharmacyId);

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
