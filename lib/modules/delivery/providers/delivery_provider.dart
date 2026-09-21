import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../models/delivery_driver.dart';
import '../services/delivery_service.dart';
import '../../../core/services/offline_sync_service.dart';

class DeliveryProvider extends ChangeNotifier {
  final DeliveryService _service = DeliveryService();
  final OfflineSyncService _offlineSync = OfflineSyncService();

  List<Delivery> _deliveries = [];
  Delivery? _selectedDelivery;
  List<DeliveryDriver> _availableDrivers = [];
  DeliveryDriver? _myDriverProfile;
  bool _isLoading = false;
  String? _error;
  // Directive standing (approuvée après Module 3) : « implementation du mode
  // offline » — même patron que les autres providers déjà audités.
  bool _isOffline = false;

  List<Delivery> get deliveries => _deliveries;
  Delivery? get selectedDelivery => _selectedDelivery;
  List<DeliveryDriver> get availableDrivers => _availableDrivers;
  DeliveryDriver? get myDriverProfile => _myDriverProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;

  List<Delivery> get activeDeliveries {
    return _deliveries.where((d) => d.isActive).toList();
  }

  List<Delivery> get pastDeliveries {
    return _deliveries.where((d) => d.isPast).toList();
  }

  // ==================== LOAD ====================

  /// driver/proof ne sont jamais inclus dans Delivery.toJson() (tables
  /// séparées) : même repli que les caches déjà audités (Modules 5/6), pour
  /// ne pas faire revenir une livraison amputée de son livreur/sa preuve
  /// après un repli hors-ligne.
  Map<String, dynamic> _toCacheJson(Delivery d) => {
    ...d.toJson(),
    if (d.driver != null) 'driver': d.driver!.toJson(),
  };

  Future<void> loadDeliveries({DeliveryStatus? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _deliveries = await _service.getDeliveries(status: status);
      _isOffline = false;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Historique patient (delivery_history_screen.dart) — même repli
  /// hors-ligne que ReservationProvider.loadPatientReservations (Module 6).
  Future<void> loadDeliveriesForPatient(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _deliveries = await _service.getDeliveriesForPatient(patientId);
      _isOffline = false;
      unawaited(
        _offlineSync.cacheDeliveries(
          patientId,
          _deliveries.map(_toCacheJson).toList(),
        ),
      );
    } catch (e) {
      final cached = await _offlineSync.getCachedDeliveries(patientId);
      if (cached.isNotEmpty) {
        _deliveries = cached.map((row) => Delivery.fromJson(row)).toList();
        _isOffline = true;
        _error =
            'Hors connexion — dernières livraisons synchronisées affichées (${_deliveries.length}).';
      } else {
        _error = e.toString();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Courses du livreur connecté (driver_dashboard_screen.dart) — corrige
  /// l'utilisation orpheline de DeliveryService.getDeliveriesForDriver
  /// (audit Module 7, 29/08/2026) : cette méthode existait côté service
  /// mais n'était appelée nulle part — l'écran livreur chargeait la liste
  /// non filtrée puis filtrait côté client sur un id en dur, ce qui de
  /// toute façon ne remontait jamais rien une fois les policies RLS
  /// d'écriture/lecture correctement scopées (voir le rapport d'audit).
  Future<void> loadDeliveriesForDriver(String driverId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final cacheKey = 'driver_$driverId';
    try {
      _deliveries = await _service.getDeliveriesForDriver(driverId);
      _isOffline = false;
      unawaited(
        _offlineSync.cacheDeliveries(
          cacheKey,
          _deliveries.map(_toCacheJson).toList(),
        ),
      );
    } catch (e) {
      final cached = await _offlineSync.getCachedDeliveries(cacheKey);
      if (cached.isNotEmpty) {
        _deliveries = cached.map((row) => Delivery.fromJson(row)).toList();
        _isOffline = true;
        _error =
            'Hors connexion — dernières courses synchronisées affichées.';
      } else {
        _error = e.toString();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDelivery(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedDelivery = await _service.getDelivery(id);
      _isOffline = false;
      _error = null;
    } catch (e) {
      final cached = await _offlineSync.getRecord('cache_deliveries', id);
      if (cached != null) {
        try {
          final data = jsonDecode(cached['data'] as String) as Map<String, dynamic>;
          _selectedDelivery = Delivery.fromJson(data);
          _isOffline = true;
          _error = 'Hors connexion — dernière version connue affichée.';
        } catch (_) {
          _error = e.toString();
        }
      } else {
        _error = e.toString();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAvailableDrivers() async {
    try {
      _availableDrivers = await _service.getAvailableDrivers();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Résout la fiche livreur (delivery_drivers) rattachée à l'utilisateur
  /// authentifié — voir DeliveryService.getDriverForUser.
  Future<void> loadMyDriverProfile(String userId) async {
    try {
      _myDriverProfile = await _service.getDriverForUser(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== ACTIONS ====================

  Future<Delivery?> scheduleDelivery({
    required String reservationId,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String deliveryAddress,
    required DateTime scheduledAt,
    bool isExpress = false,
    bool isColdChainRequired = false,
    String? pickupPointId,
    String? pickupPointName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final delivery = await _service.scheduleDelivery(
        reservationId: reservationId,
        patientId: patientId,
        patientName: patientName,
        patientPhone: patientPhone,
        deliveryAddress: deliveryAddress,
        scheduledAt: scheduledAt,
        isExpress: isExpress,
        isColdChainRequired: isColdChainRequired,
        pickupPointId: pickupPointId,
        pickupPointName: pickupPointName,
      );
      _deliveries.add(delivery);
      _isLoading = false;
      notifyListeners();
      return delivery;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> assignDriver(String deliveryId, String driverId) async {
    try {
      final updated = await _service.assignDriver(deliveryId, driverId);
      _updateDelivery(updated);
      return true;
    } catch (e) {
      // Bug corrigé (audit Module 7, 29/08/2026) : notifyListeners()
      // manquait sur ce chemin d'erreur (et sur celui des méthodes
      // symétriques ci-dessous) — un écran qui observe `provider.error` via
      // context.watch plutôt qu'en lisant le résultat juste après l'await
      // ne se redessinait pas tout de suite pour afficher l'échec.
      _error = e is StateError ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> startDelivery(String deliveryId) async {
    try {
      final updated = await _service.startDelivery(deliveryId);
      _updateDelivery(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsArrived(String deliveryId) async {
    try {
      final updated = await _service.markAsArrived(deliveryId);
      _updateDelivery(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeDelivery({
    required String deliveryId,
    String? signatureData,
    String? imageUrl,
    String? enteredConfirmationCode,
    String? recipientName,
    String? recipientPhone,
    String? notes,
  }) async {
    try {
      final updated = await _service.completeDelivery(
        deliveryId: deliveryId,
        signatureData: signatureData,
        imageUrl: imageUrl,
        enteredConfirmationCode: enteredConfirmationCode,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        notes: notes,
      );
      _updateDelivery(updated);
      return true;
    } catch (e) {
      _error = e is StateError ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelDelivery(String deliveryId, {String? reason}) async {
    try {
      final updated = await _service.cancelDelivery(deliveryId, reason: reason);
      _updateDelivery(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Position du livreur lui-même (fiche delivery_drivers) — utilisée pour
  /// afficher sa disponibilité/position aux autres écrans. Voir
  /// updateDeliveryLocation ci-dessous pour la position rattachée à UNE
  /// livraison précise (celle affichée sur la carte du patient).
  Future<void> updateMyLocation(
    String driverId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _service.updateDriverLocation(driverId, latitude, longitude);
    } catch (_) {
      // Best-effort : une mise à jour de position isolée qui échoue ne doit
      // pas interrompre la course en cours ni afficher d'erreur bloquante.
    }
  }

  /// Position affichée sur la carte de suivi du patient pour la livraison en
  /// cours (delivery_tracking_screen.dart). Audit Module 7 (29/08/2026) :
  /// DeliveryService.updateLocation existait déjà mais n'avait aucun
  /// appelant — la carte affichait donc toujours la position figée au
  /// moment de la planification, jamais la position réelle du livreur
  /// pendant la course, malgré "Suivi en temps réel de la course" et "Carte
  /// de suivi temps réel" (fonctionnalités clés / écrans du cahier).
  Future<void> updateDeliveryLocation(
    String deliveryId,
    double latitude,
    double longitude,
  ) async {
    try {
      final updated = await _service.updateLocation(
        deliveryId: deliveryId,
        latitude: latitude,
        longitude: longitude,
      );
      _updateDelivery(updated);
    } catch (_) {
      // Best-effort — voir updateMyLocation.
    }
  }

  void _updateDelivery(Delivery updated) {
    final index = _deliveries.indexWhere((d) => d.id == updated.id);
    if (index != -1) _deliveries[index] = updated;
    if (_selectedDelivery?.id == updated.id) _selectedDelivery = updated;
    notifyListeners();
  }

  void clearSelected() {
    _selectedDelivery = null;
    notifyListeners();
  }
}
