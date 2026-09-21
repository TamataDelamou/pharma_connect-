import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import '../models/stock_batch.dart';
import '../models/stock_status.dart';
import '../models/stock_adjustment.dart';
import '../services/stock_service.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../alerts/services/alert_service.dart';

class StockProvider extends ChangeNotifier {
  final StockService _service = StockService();
  final OfflineSyncService _offline = OfflineSyncService();
  final AlertService _alertService = AlertService();

  List<StockItem> _stockItems = [];
  StockItem? _selectedStockItem;
  List<StockMovement> _movements = [];
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;
  String? _selectedProductId;
  // Directive standing « privilégier le mode hors-ligne » (Module 4, STK) :
  // vrai quand la dernière lecture/écriture réussie ne l'a été que depuis le
  // cache local, pas depuis le serveur — même patron que SearchProvider
  // (Module 2) pour rester cohérent dans toute l'app.
  bool _isOffline = false;

  // Getters
  List<StockItem> get stockItems => _stockItems;
  StockItem? get selectedStockItem => _selectedStockItem;
  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;
  bool get isOffline => _isOffline;

  // ==================== CHARGEMENT ====================

  /// `pharmacyId` (audit Module 4, 29/08/2026) : sans ce paramètre, le stock
  /// de toutes les officines apparaissait mélangé dans une même liste (voir
  /// StockItem/StockService). Les écrans le fournissent depuis
  /// `AuthProvider.pharmacyId`. Reste optionnel pour ne pas casser un futur
  /// usage back-office toutes-officines (is_gsg_admin).
  Future<void> loadStock({
    String? pharmacyId,
    String? productId,
    String? searchQuery,
  }) async {
    _isLoading = true;
    _error = null;
    _selectedProductId = productId;
    _searchQuery = searchQuery;
    notifyListeners();

    try {
      final rawItems = await _service.getStockItemsRaw(
        pharmacyId: pharmacyId,
        productId: productId,
      );
      var items = rawItems.map((row) => StockItem.fromJson(row)).toList();
      items = _applySearch(items, searchQuery);

      _stockItems = items;
      _isOffline = false;
      if (pharmacyId != null) {
        // Best-effort : une erreur de cache ne doit jamais faire échouer un
        // chargement réseau par ailleurs réussi.
        unawaited(_offline.cacheStockItems(pharmacyId, rawItems));
        // OfflineSyncService.syncAll() n'était déclenché nulle part dans
        // l'app (aucun listener de connectivité global, aucun appel dans
        // main.dart/app.dart) — une écriture mise en file d'attente hors-
        // ligne y serait restée indéfiniment. Un chargement réseau réussi
        // est la preuve la plus simple que la connexion est revenue : on en
        // profite pour vider la file en tâche de fond, sans bloquer l'UI.
        unawaited(_offline.syncAll());
      }
    } catch (e) {
      final fallback = pharmacyId != null
          ? await _tryOfflineFallback(pharmacyId, searchQuery)
          : false;
      if (!fallback) {
        _error = e.toString();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _tryOfflineFallback(
    String pharmacyId,
    String? searchQuery,
  ) async {
    try {
      final cached = await _offline.getCachedStockItems(pharmacyId);
      if (cached.isEmpty) return false;
      var items = cached.map((row) => StockItem.fromJson(row)).toList();
      items = _applySearch(items, searchQuery);
      _stockItems = items;
      _isOffline = true;
      _error =
          'Connexion indisponible — stock affiché depuis la dernière '
          'synchronisation locale, possiblement pas à jour.';
      return true;
    } catch (_) {
      return false;
    }
  }

  List<StockItem> _applySearch(List<StockItem> items, String? searchQuery) {
    if (searchQuery == null || searchQuery.isEmpty) return items;
    final lower = searchQuery.toLowerCase();
    return items
        .where(
          (item) =>
              item.product.name.toLowerCase().contains(lower) ||
              item.product.genericName.toLowerCase().contains(lower) ||
              item.product.manufacturer.toLowerCase().contains(lower),
        )
        .toList();
  }

  Future<void> loadStockItem(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedStockItem = await _service.getStockItem(id);
      if (_selectedStockItem != null) {
        _movements = await _service.getMovements(stockItemId: id);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMovements({String? stockItemId, String? batchId}) async {
    try {
      _movements = await _service.getMovements(
        stockItemId: stockItemId,
        batchId: batchId,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== ACTIONS ====================

  Future<bool> reserveStock({
    required String productId,
    required String pharmacyId,
    required int quantity,
    String? referenceId,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.reserveStock(
        productId: productId,
        pharmacyId: pharmacyId,
        quantity: quantity,
        referenceId: referenceId,
        userId: userId,
      );
      _isLoading = false;
      notifyListeners();
      // Recharger pour mettre à jour l'UI
      await loadStock(
        pharmacyId: pharmacyId,
        productId: _selectedProductId,
        searchQuery: _searchQuery,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmReservation({
    required String productId,
    required String pharmacyId,
    required int quantity,
    String? referenceId,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.confirmReservation(
        productId: productId,
        pharmacyId: pharmacyId,
        quantity: quantity,
        referenceId: referenceId,
        userId: userId,
      );
      _isLoading = false;
      notifyListeners();
      await loadStock(
        pharmacyId: pharmacyId,
        productId: _selectedProductId,
        searchQuery: _searchQuery,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelReservation({
    required String productId,
    required String pharmacyId,
    required int quantity,
    String? referenceId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.cancelReservation(
        productId: productId,
        pharmacyId: pharmacyId,
        quantity: quantity,
        referenceId: referenceId,
      );
      _isLoading = false;
      notifyListeners();
      await loadStock(
        pharmacyId: pharmacyId,
        productId: _selectedProductId,
        searchQuery: _searchQuery,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== FILTRES ====================

  void search(String query, {String? pharmacyId}) {
    loadStock(
      pharmacyId: pharmacyId,
      productId: _selectedProductId,
      searchQuery: query,
    );
  }

  void clearFilters({String? pharmacyId}) {
    _selectedProductId = null;
    _searchQuery = null;
    loadStock(pharmacyId: pharmacyId);
  }

  void clearSelected() {
    _selectedStockItem = null;
    _movements = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Ajouter ces getters et méthodes

  List<StockItem> get lowStockItems =>
      _stockItems.where((item) => item.isLowStock).toList();
  List<StockItem> get criticalStockItems =>
      _stockItems.where((item) => item.isCriticalStock).toList();
  List<StockItem> get outOfStockItems =>
      _stockItems.where((item) => item.isOutOfStock).toList();

  Future<void> loadAlerts({String? pharmacyId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = await _service.getStockItems(pharmacyId: pharmacyId);
      _stockItems = items;
      _isOffline = false;
      // Module 10 (ALR, audit 29/08/2026) : câblage de generateStockAlert/
      // generateExpiryAlert (jusqu'ici jamais appelées, voir registre D6 et
      // audit Module 10) au seul écran qui consulte déjà l'état réel du
      // stock d'une officine. best-effort et non bloquant (unawaited) :
      // l'écran « Alertes de stock » doit continuer à fonctionner même si la
      // génération d'alertes échoue (ex. policy RLS pas encore déployée).
      if (pharmacyId != null) {
        unawaited(_generateStockAndExpiryAlerts(pharmacyId, items));
      }
    } catch (e) {
      final fallback = pharmacyId != null
          ? await _tryOfflineFallback(pharmacyId, null)
          : false;
      if (!fallback) {
        _error = e.toString();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// RG-ALR-01 (stock) et RG-ALR-02 (péremption) : voir le rapport d'audit
  /// Module 10 pour la nuance entre le seuil statique utilisé ici
  /// (thresholdLow/thresholdCritical réels de l'article, déjà en place
  /// depuis le Module 4) et la formulation du cahier (« 3 jours de
  /// consommation moyenne ») — cette dernière demanderait un calcul de
  /// vélocité des ventes qui n'existe nulle part dans l'app aujourd'hui, et
  /// relève plutôt du Module 28 (BI/Analytics), pas de ce module. Écart
  /// documenté au registre plutôt que traité en silence.
  Future<void> _generateStockAndExpiryAlerts(
    String pharmacyId,
    List<StockItem> items,
  ) async {
    for (final item in items) {
      if (!item.isLowStock && !item.isCriticalStock && !item.isOutOfStock) {
        continue;
      }
      try {
        await _alertService.generateStockAlert(
          productName: item.product.name,
          quantity: item.availableQuantity,
          stockItemId: item.id,
          pharmacyId: pharmacyId,
          thresholdLow: item.thresholdLow,
          thresholdCritical: item.thresholdCritical,
        );
      } catch (_) {
        // Best-effort : une alerte manquée ne doit jamais faire échouer
        // l'affichage du stock lui-même.
      }
    }

    try {
      // Horizon 60 jours : aligné sur RG-ALR-02 (péremption à 60 jours) plutôt
      // que sur le défaut interne de generateExpiryAlert (30 jours, qui reste
      // le seuil utilisé pour distinguer alerte simple/urgente à l'intérieur
      // de cette fenêtre).
      final expiringBatches = await _service.getExpiringBatches(
        pharmacyId: pharmacyId,
        daysThreshold: 60,
      );
      for (final batch in expiringBatches) {
        // Pas de dépendance package:collection dans ce projet (non confirmée
        // dans pubspec.yaml) : recherche manuelle plutôt que
        // firstWhereOrNull, pour rester cohérent avec le reste du fichier.
        StockItem? item;
        for (final candidate in items) {
          if (candidate.batches.any((b) => b.id == batch.id)) {
            item = candidate;
            break;
          }
        }
        if (item == null) continue;
        try {
          await _alertService.generateExpiryAlert(
            productName: item.product.name,
            batchNumber: batch.batchNumber,
            expiryDate: batch.expiryDate,
            batchId: batch.id,
            pharmacyId: pharmacyId,
            daysThreshold: 60,
          );
        } catch (_) {
          // Best-effort, idem.
        }
      }
    } catch (_) {
      // getExpiringBatches elle-même a pu échouer (réseau) : pas bloquant.
    }
  }

  /// Audit Module 4 (29/08/2026) : `userId`/`pharmacyId` désormais requis et
  /// réels (voir StockAdjustmentScreen — auparavant 'admin'/'Admin' codés en
  /// dur, ce qui faisait échouer chaque ajustement : user_id est une colonne
  /// `uuid`, la chaîne littérale 'admin' n'est pas castable). Hors-ligne
  /// (directive standing) : l'ajustement est appliqué optimistiquement au
  /// cache local et mis en file d'attente (`OfflineSyncService.syncAll`) au
  /// lieu d'échouer — limité au cas sans sélection de lot explicite (aucun
  /// écran actuel n'en propose), documenté dans le rapport de module.
  Future<bool> adjustStock({
    required String pharmacyId,
    required String productId,
    required int quantity,
    required AdjustmentReason reason,
    String? batchId,
    required String userId,
    String? userName,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final online = await _offline.hasInternet();
    if (!online) {
      final queued = await _queueOfflineAdjustment(
        pharmacyId: pharmacyId,
        productId: productId,
        quantity: quantity,
        reason: reason,
        userId: userId,
        userName: userName,
        notes: notes,
      );
      _isLoading = false;
      _isOffline = true;
      if (!queued) {
        _error =
            'Ajustement impossible hors-ligne : ce produit n\'a pas encore '
            'été synchronisé sur cet appareil.';
      }
      notifyListeners();
      if (queued) {
        await loadStock(pharmacyId: pharmacyId);
      }
      return queued;
    }

    try {
      final result = await _service.adjustStock(
        productId: productId,
        pharmacyId: pharmacyId,
        quantity: quantity,
        reason: reason,
        batchId: batchId,
        userId: userId,
        userName: userName,
        notes: notes,
      );
      _isLoading = false;
      _isOffline = false;
      notifyListeners();
      await loadStock(pharmacyId: pharmacyId);
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Met en file d'attente les trois écritures qu'un ajustement réel produit
  /// côté serveur (stock_items, stock_adjustments, stock_movements) via la
  /// file générique déjà existante (OfflineSyncService.syncAll les rejouera
  /// telles quelles à la reconnexion), et applique le même delta au cache
  /// local pour que l'écran liste reflète l'ajustement immédiatement.
  /// Retourne false si le produit n'est pas encore en cache sur cet
  /// appareil (rien à ajuster sans une lecture en ligne préalable).
  Future<bool> _queueOfflineAdjustment({
    required String pharmacyId,
    required String productId,
    required int quantity,
    required AdjustmentReason reason,
    required String userId,
    String? userName,
    String? notes,
  }) async {
    final cached = await _offline.getCachedStockItems(pharmacyId);
    Map<String, dynamic>? match;
    for (final item in cached) {
      if (item['product_id'] == productId) {
        match = item;
        break;
      }
    }
    if (match == null) return false;

    final stockItemId = match['id'] as String;
    final currentTotal = match['total_quantity'] as int? ?? 0;
    final newTotal = currentTotal + quantity;
    final thresholdLow = match['threshold_low'] as int? ?? 20;
    final thresholdCritical = match['threshold_critical'] as int? ?? 5;
    final newStatus = StockService.computeStockStatus(
      newTotal,
      thresholdLow,
      thresholdCritical,
    ).name;

    final now = DateTime.now();
    final adjustmentId = const Uuid().v4();
    final movementId = const Uuid().v4();

    await _offline.queueOperation(
      table: 'stock_items',
      recordId: stockItemId,
      operation: 'update',
      data: {'total_quantity': newTotal, 'status': newStatus},
    );
    await _offline.queueOperation(
      table: 'stock_adjustments',
      recordId: adjustmentId,
      operation: 'insert',
      data: {
        'id': adjustmentId,
        'stock_item_id': stockItemId,
        'reason': reason.name,
        'quantity': quantity,
        'user_id': userId,
        'user_name': userName,
        'notes': notes?.isNotEmpty == true ? notes : reason.label,
        'timestamp': now.toIso8601String(),
      },
    );
    await _offline.queueOperation(
      table: 'stock_movements',
      recordId: movementId,
      operation: 'insert',
      data: {
        'id': movementId,
        'stock_item_id': stockItemId,
        'type': 'adjustment',
        'quantity': quantity,
        'timestamp': now.toIso8601String(),
        'user_id': userId,
        'user_name': userName,
        'notes': notes?.isNotEmpty == true ? notes : reason.label,
      },
    );
    await _offline.patchCachedStockItem(pharmacyId, stockItemId, {
      'total_quantity': newTotal,
      'status': newStatus,
    });

    return true;
  }

  Future<bool> transferStock({
    required String productId,
    required int quantity,
    required String fromPharmacyId,
    required String toPharmacyId,
    String? userId,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.transferStock(
        productId: productId,
        quantity: quantity,
        fromPharmacyId: fromPharmacyId,
        toPharmacyId: toPharmacyId,
        userId: userId,
        notes: notes,
      );
      _isLoading = false;
      notifyListeners();
      await loadStock(pharmacyId: fromPharmacyId);
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Module 10 (ALR, arbitrage D15, 29/08/2026) : écran « Paramétrage des
  /// seuils » — met à jour immédiatement la liste en mémoire (les seuils
  /// affichés dans _stockItems doivent refléter l'édition sans attendre un
  /// rechargement complet) plutôt que de forcer un aller-retour réseau.
  Future<bool> updateThresholds({
    required String stockItemId,
    required int thresholdLow,
    required int thresholdCritical,
  }) async {
    try {
      final success = await _service.updateThresholds(
        stockItemId: stockItemId,
        thresholdLow: thresholdLow,
        thresholdCritical: thresholdCritical,
      );
      if (success) {
        final index = _stockItems.indexWhere((i) => i.id == stockItemId);
        if (index != -1) {
          final current = _stockItems[index];
          _stockItems[index] = current.copyWith(
            thresholdLow: thresholdLow,
            thresholdCritical: thresholdCritical,
            status: StockService.computeStockStatus(
              current.availableQuantity,
              thresholdLow,
              thresholdCritical,
            ),
          );
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<StockBatch>> getExpiringBatches({
    String? pharmacyId,
    int daysThreshold = 30,
  }) async {
    try {
      return await _service.getExpiringBatches(
        pharmacyId: pharmacyId,
        daysThreshold: daysThreshold,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> advancedSearch({
    String? pharmacyId,
    String? query,
    String? batchNumber,
    String? supplierId,
    DateTime? expiryBefore,
    DateTime? expiryAfter,
    StockStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stockItems = await _service.searchStock(
        pharmacyId: pharmacyId,
        query: query,
        batchNumber: batchNumber,
        supplierId: supplierId,
        expiryBefore: expiryBefore,
        expiryAfter: expiryAfter,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
