import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/offline_sync_service.dart';
import '../models/demand_forecast.dart';
import '../services/forecast_service.dart';

class StockForecastProvider extends ChangeNotifier {
  final ForecastService _service = ForecastService();
  final OfflineSyncService _offlineSync = OfflineSyncService();

  List<DemandForecast> _forecasts = [];
  List<ReorderAlert> _reorderAlerts = [];
  Map<String, dynamic>? _simulationResult;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isOffline = false;
  String? _error;

  List<DemandForecast> get forecasts => _forecasts;
  List<ReorderAlert> get reorderAlerts => _reorderAlerts;
  Map<String, dynamic>? get simulationResult => _simulationResult;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isOffline => _isOffline;
  String? get error => _error;

  Future<void> generateForecasts({
    required String productId,
    required String pharmacyId,
    int days = 14,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      _forecasts = await _service.generateDemandForecast(
        productId: productId,
        pharmacyId: pharmacyId,
        days: days,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isGenerating = false;
    notifyListeners();
  }

  // Audit Module 11 (29/08/2026) : cette méthode appelait `_client.from(...)`
  // alors qu'aucun champ `_client` n'existe (ni import Supabase) dans cette
  // classe — identifiant non défini, donc erreur de compilation qui aurait
  // bloqué l'analyse/le build de TOUT le projet dès l'inclusion de ce
  // fichier, indépendamment du fait que `loadForecasts` soit appelée ou non.
  // Corrigé en passant par `ForecastService` (le provider ne doit jamais
  // parler directement à Supabase, cohérent avec le reste de l'app).
  // Audit Module 11 (29/08/2026) : lecture mise en cache local + repli
  // hors-ligne, même patron que AlertProvider (Module 10) — directive
  // standing « privilégier le mode hors-ligne ». owner_key = pharmacyId
  // (écran scopé officine).
  Future<void> loadForecasts(String pharmacyId) async {
    _isLoading = true;
    _error = null;
    _isOffline = false;
    notifyListeners();
    try {
      _forecasts = await _service.getForecasts(pharmacyId);
      unawaited(
        _offlineSync.cacheForecasts(
          pharmacyId,
          _forecasts.map((f) => f.toJson()).toList(),
        ),
      );
    } catch (e) {
      final fallback = await _tryOfflineForecasts(pharmacyId);
      if (!fallback) _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _tryOfflineForecasts(String pharmacyId) async {
    try {
      final cached = await _offlineSync.getCachedForecasts(pharmacyId);
      if (cached.isEmpty) return false;
      _forecasts = cached.map((json) => DemandForecast.fromJson(json)).toList();
      _isOffline = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> checkAlerts(String pharmacyId) async {
    _isLoading = true;
    _error = null;
    _isOffline = false;
    notifyListeners();
    try {
      _reorderAlerts = await _service.checkReorderAlerts(pharmacyId);
      unawaited(
        _offlineSync.cacheReorderAlerts(
          pharmacyId,
          _reorderAlerts.map((a) => a.toJson()).toList(),
        ),
      );
    } catch (e) {
      final fallback = await _tryOfflineReorders(pharmacyId);
      if (!fallback) _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // Audit Module 11 (29/08/2026), arbitrage D17 : utilisé par l'écran
  // « Commande recommandée » — lit les alertes déjà générées sans en créer
  // de nouvelles (contrairement à checkAlerts, qui recalcule et insère).
  Future<void> loadPendingReorders(String pharmacyId) async {
    _isLoading = true;
    _error = null;
    _isOffline = false;
    notifyListeners();
    try {
      _reorderAlerts = await _service.getPendingReorderAlerts(pharmacyId);
      unawaited(
        _offlineSync.cacheReorderAlerts(
          pharmacyId,
          _reorderAlerts.map((a) => a.toJson()).toList(),
        ),
      );
    } catch (e) {
      final fallback = await _tryOfflineReorders(pharmacyId);
      if (!fallback) _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _tryOfflineReorders(String pharmacyId) async {
    try {
      final cached = await _offlineSync.getCachedReorderAlerts(pharmacyId);
      if (cached.isEmpty) return false;
      _reorderAlerts = cached.map((json) => ReorderAlert.fromJson(json)).toList();
      _isOffline = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> validateReorder({
    required String alertId,
    required int quantityToOrder,
  }) async {
    final success = await _service.validateReorder(
      alertId: alertId,
      quantityToOrder: quantityToOrder,
    );
    if (success) {
      _reorderAlerts = _reorderAlerts
          .where((a) => a.id != alertId)
          .toList();
      notifyListeners();
    }
    return success;
  }

  Future<bool> dismissReorder(String alertId) async {
    final success = await _service.dismissReorder(alertId);
    if (success) {
      _reorderAlerts = _reorderAlerts
          .where((a) => a.id != alertId)
          .toList();
      notifyListeners();
    }
    return success;
  }

  Future<void> runSimulation({
    required String pharmacyId,
    required String name,
    required Map<String, dynamic> parameters,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _simulationResult = await _service.simulateScenario(
        pharmacyId: pharmacyId,
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
