import 'dart:async';
import 'package:flutter/material.dart';
import '../models/b2b_offer.dart';
import '../models/b2b_order.dart';
import '../models/b2b_negotiation.dart';
import '../services/marketplace_service.dart';
import 'package:pharma_connect/core/services/offline_sync_service.dart';

class MarketplaceProvider extends ChangeNotifier {
  final MarketplaceService _service = MarketplaceService();
  final OfflineSyncService _offline = OfflineSyncService();

  List<B2BOffer> _offers = [];
  B2BOffer? _selectedOffer;
  List<B2BOrder> _orders = [];
  B2BOrder? _selectedOrder;
  List<B2BNegotiation> _negotiations = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;

  List<B2BOffer> get offers => _offers;
  B2BOffer? get selectedOffer => _selectedOffer;
  List<B2BOrder> get orders => _orders;
  B2BOrder? get selectedOrder => _selectedOrder;
  List<B2BNegotiation> get negotiations => _negotiations;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get error => _error;

  // ---- Offers ----

  /// Audit Module 13 (B2B, 29/08/2026) : directive standing « privilégier
  /// le mode hors-ligne », même patron que StockProvider.loadStock() (Module
  /// 4). Le repli sur cache local couvre le catalogue global (`cache_b2b_offers`).
  ///
  /// Extension (clôture, 29/08/2026) : arbitrage explicite du porteur du
  /// projet — étendre également un cache minimal en lecture à « Mes offres »
  /// (`cache_my_b2b_offers`, owner_key = sellerPharmacyId), même patron
  /// owner_key que cache_prescriptions/cache_reservations. Reste en ligne
  /// uniquement : créer/modifier/supprimer une offre — seule la LECTURE
  /// bénéficie du repli, cohérent avec PAY (D13) et le catalogue global de
  /// ce même module.
  Future<void> loadOffers({
    String? sellerPharmacyId,
    String? productId,
    String? status,
    bool onlyActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final isGlobalCatalog = sellerPharmacyId == null && productId == null;
    final isMyOffers = sellerPharmacyId != null && productId == null;
    try {
      _offers = await _service.getOffers(
        sellerPharmacyId: sellerPharmacyId,
        productId: productId,
        status: status,
        onlyActive: onlyActive,
      );
      _isOffline = false;
      // Best-effort : une erreur de cache ne doit jamais faire échouer un
      // chargement réseau par ailleurs réussi.
      if (isGlobalCatalog) {
        unawaited(_cacheOffers(_offers));
        unawaited(_offline.syncAll());
      } else if (isMyOffers) {
        unawaited(_cacheMyOffers(sellerPharmacyId, _offers));
        unawaited(_offline.syncAll());
      }
    } catch (e) {
      bool fallback = false;
      if (isGlobalCatalog) {
        fallback = await _tryOfflineFallback();
      } else if (isMyOffers) {
        fallback = await _tryMyOffersOfflineFallback(sellerPharmacyId);
      }
      if (!fallback) {
        _error = e.toString();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _cacheOffers(List<B2BOffer> items) async {
    final raw = items.map((o) {
      final json = o.toJson();
      if (o.sellerName != null) {
        json['sellers'] = {'name': o.sellerName};
      }
      return json;
    }).toList();
    await _offline.cacheB2BOffers(raw);
  }

  Future<bool> _tryOfflineFallback() async {
    try {
      final cached = await _offline.getCachedB2BOffers();
      if (cached.isEmpty) return false;
      _offers = cached.map((row) => B2BOffer.fromJson(row)).toList();
      _isOffline = true;
      _error =
          'Connexion indisponible — offres affichées depuis la dernière '
          'synchronisation locale, possiblement pas à jour.';
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cacheMyOffers(String ownerKey, List<B2BOffer> items) async {
    final raw = items.map((o) {
      final json = o.toJson();
      if (o.sellerName != null) {
        json['sellers'] = {'name': o.sellerName};
      }
      return json;
    }).toList();
    await _offline.cacheMyB2BOffers(ownerKey, raw);
  }

  Future<bool> _tryMyOffersOfflineFallback(String ownerKey) async {
    try {
      final cached = await _offline.getCachedMyB2BOffers(ownerKey);
      if (cached.isEmpty) return false;
      _offers = cached.map((row) => B2BOffer.fromJson(row)).toList();
      _isOffline = true;
      _error =
          'Connexion indisponible — vos offres affichées depuis la '
          'dernière synchronisation locale, possiblement pas à jour.';
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Audit Module 13 (B2B, 29/08/2026, clôture) : réserve levée — utilisée
  /// par l'écran « Mes offres » pour avertir avant suppression si l'offre
  /// est déjà référencée par des commandes existantes. Best-effort : un
  /// échec de ce contrôle diagnostique ne doit jamais bloquer la tentative
  /// de suppression elle-même (l'utilisateur reste averti par l'absence
  /// d'avertissement plutôt que par une erreur bloquante).
  Future<int> countLinkedOrdersForOffer(String offerId) async {
    try {
      return await _service.countOrderItemsForOffer(offerId);
    } catch (_) {
      return 0;
    }
  }

  /// Audit Module 13 (B2B, 29/08/2026, deuxième passe de clôture) : contrôle
  /// diagnostique complémentaire — contrairement à `b2b_order_items.offer_id`
  /// (`on delete set null`, voir countLinkedOrdersForOffer), `b2b_negotiations
  /// .offer_id` est `on delete cascade` (migration de base) : supprimer une
  /// offre supprime silencieusement et définitivement tout son historique de
  /// négociation. Best-effort, même logique que countLinkedOrdersForOffer.
  Future<int> countNegotiationsForOffer(String offerId) async {
    try {
      final negotiations = await _service.getNegotiationsForOffer(offerId);
      return negotiations.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> loadOffer(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedOffer = await _service.getOffer(id);
      if (_selectedOffer != null) {
        await loadNegotiations(_selectedOffer!.id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveOffer(B2BOffer offer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      B2BOffer saved;
      if (offer.id.isEmpty || offer.id.startsWith('temp_')) {
        saved = await _service.createOffer(offer);
        _offers.insert(0, saved);
      } else {
        saved = await _service.updateOffer(offer);
        final index = _offers.indexWhere((o) => o.id == saved.id);
        if (index != -1) _offers[index] = saved;
      }
      _selectedOffer = saved;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOffer(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteOffer(id);
      _offers.removeWhere((o) => o.id == id);
      if (_selectedOffer?.id == id) _selectedOffer = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---- Orders ----

  /// Audit Module 13 (B2B, 29/08/2026, clôture) : arbitrage explicite du
  /// porteur du projet — extension du mode hors-ligne à « Mes commandes »
  /// (`cache_b2b_orders`, owner_key = involvedPharmacyId), même patron que
  /// « Mes offres » ci-dessus. Ne couvre que l'appel `involvedPharmacyId`
  /// (le seul réellement utilisé par marketplace_home_screen.dart) ; les
  /// paramètres `buyerPharmacyId`/`sellerPharmacyId` séparés restent sans
  /// repli hors-ligne, aucun appelant actuel ne les utilise seuls.
  Future<void> loadOrders({
    String? buyerPharmacyId,
    String? sellerPharmacyId,
    String? involvedPharmacyId,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _service.getOrders(
        buyerPharmacyId: buyerPharmacyId,
        sellerPharmacyId: sellerPharmacyId,
        involvedPharmacyId: involvedPharmacyId,
        status: status,
      );
      _isOffline = false;
      if (involvedPharmacyId != null) {
        unawaited(_cacheOrders(involvedPharmacyId, _orders));
        unawaited(_offline.syncAll());
      }
    } catch (e) {
      final fallback = involvedPharmacyId != null
          ? await _tryOrdersOfflineFallback(involvedPharmacyId)
          : false;
      if (!fallback) {
        _error = e.toString();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _cacheOrders(String ownerKey, List<B2BOrder> items) async {
    final raw = items.map((o) {
      final json = o.toJson();
      if (o.buyerName != null) json['buyers'] = {'name': o.buyerName};
      if (o.sellerName != null) json['sellers'] = {'name': o.sellerName};
      if (o.items != null) {
        json['items'] = o.items!.map((it) => it.toJson()).toList();
      }
      return json;
    }).toList();
    await _offline.cacheB2BOrders(ownerKey, raw);
  }

  Future<bool> _tryOrdersOfflineFallback(String ownerKey) async {
    try {
      final cached = await _offline.getCachedB2BOrders(ownerKey);
      if (cached.isEmpty) return false;
      _orders = cached.map((row) => B2BOrder.fromJson(row)).toList();
      _isOffline = true;
      _error =
          'Connexion indisponible — vos commandes affichées depuis la '
          'dernière synchronisation locale, possiblement pas à jour.';
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadOrder(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedOrder = await _service.getOrder(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveOrder(B2BOrder order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      B2BOrder saved;
      if (order.id.isEmpty || order.id.startsWith('temp_')) {
        saved = await _service.createOrder(order);
        _orders.insert(0, saved);
      } else {
        saved = await _service.updateOrder(order);
        final index = _orders.indexWhere((o) => o.id == saved.id);
        if (index != -1) _orders[index] = saved;
      }
      _selectedOrder = saved;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(String id, String newStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateOrderStatus(id, newStatus);
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) _orders[index] = updated;
      if (_selectedOrder?.id == id) _selectedOrder = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---- Negotiations ----

  Future<void> loadNegotiations(String offerId) async {
    try {
      _negotiations = await _service.getNegotiationsForOffer(offerId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> createNegotiation(B2BNegotiation negotiation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createNegotiation(negotiation);
      _negotiations.add(saved);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNegotiation(B2BNegotiation negotiation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.updateNegotiation(negotiation);
      final index = _negotiations.indexWhere((n) => n.id == saved.id);
      if (index != -1) _negotiations[index] = saved;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearSelected() {
    _selectedOffer = null;
    _selectedOrder = null;
    _negotiations = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
