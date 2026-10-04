import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pickup_line.dart';
import '../models/reservation.dart';
import '../models/reservation_item.dart';
import '../models/reservation_status.dart';
import '../models/timeslot.dart';
import '../services/reservation_service.dart';
import '../../../core/services/offline_sync_service.dart';

class ReservationProvider extends ChangeNotifier {
  final ReservationService _service = ReservationService();
  final OfflineSyncService _offlineSync = OfflineSyncService();

  List<Reservation> _reservations = [];
  Reservation? _selectedReservation;
  final List<ReservationItem> _cartItems = [];
  List<TimeSlot> _availableSlots = [];
  TimeSlot? _selectedSlot;
  bool _isLoading = false;
  String? _selectedPharmacyId;
  String? _selectedPharmacyName;
  String? _selectedPharmacyAddress;
  String? _selectedPharmacyPhone;
  String? _error;
  int? _queuePosition;
  int? _estimatedWaitMinutes;
  // Directive standing (approuvée après Module 3) : « implementation du mode
  // offline » — en cas d'échec réseau, on conserve les dernières données
  // connues (cache local) plutôt que de basculer sur un état d'erreur
  // bloquant. C243 : lecture seulement ; réserver, annuler et retirer
  // exigent le réseau.
  bool _isOffline = false;
  // C243 : réservations actives dont un produit n'est plus disponible (lot
  // rappelé ou périmé depuis la réservation), avec les produits concernés.
  Map<String, List<String>> _unavailableItems = {};
  // C243 : aperçu du retrait en cours (écran de retrait de l'officine).
  List<PickupLine> _pickupLines = [];

  // Getters
  List<Reservation> get reservations => _reservations;
  Reservation? get selectedReservation => _selectedReservation;
  List<ReservationItem> get cartItems => _cartItems;
  List<TimeSlot> get availableSlots => _availableSlots;
  TimeSlot? get selectedSlot => _selectedSlot;
  bool get isLoading => _isLoading;
  String? get selectedPharmacyId => _selectedPharmacyId;
  String? get selectedPharmacyName => _selectedPharmacyName;
  String? get selectedPharmacyAddress => _selectedPharmacyAddress;
  String? get selectedPharmacyPhone => _selectedPharmacyPhone;
  String? get error => _error;
  int? get queuePosition => _queuePosition;
  int? get estimatedWaitMinutes => _estimatedWaitMinutes;
  bool get isOffline => _isOffline;
  List<PickupLine> get pickupLines => _pickupLines;

  /// Produits d'une réservation active qui ne sont plus disponibles.
  List<String> unavailableProductsOf(String reservationId) =>
      _unavailableItems[reservationId] ?? const [];

  int get cartTotal {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get hasItemsInCart => _cartItems.isNotEmpty;

  List<Reservation> get activeReservations {
    return _reservations.where((r) => r.isActive && !r.isOverdue).toList();
  }

  List<Reservation> get completedReservations {
    return _reservations.where((r) => !r.isActive || r.isOverdue).toList();
  }

  // ==================== LOAD ====================

  /// items n'est jamais inclus dans Reservation.toJson() (table séparée) :
  /// même repli que PrescriptionProvider._toCacheJson (Module 5), pour ne
  /// pas faire revenir une réservation sans contenu de panier après un repli
  /// hors-ligne.
  Map<String, dynamic> _toCacheJson(Reservation r) => {
    ...r.toJson(),
    'reservation_items': r.items
        .map((i) => i.toJson(reservationId: r.id))
        .toList(),
  };

  Future<void> loadReservations({ReservationStatus? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reservations = await _service.getReservations(status: status);
      _isOffline = false;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPatientReservations(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // C243 : plus d'expiration faite par l'application. Le serveur expire
      // les réservations dépassées (tâche planifiée) ; d'ici là, une
      // réservation dont l'échéance est passée est affichée « expirée »
      // (Reservation.isOverdue).
      _reservations = await _service.getReservationsForPatient(patientId);
      _unavailableItems = await _service.getUnavailableItems();
      _isOffline = false;
      unawaited(
        _offlineSync.cacheReservations(
          patientId,
          _reservations.map(_toCacheJson).toList(),
        ),
      );
    } catch (e) {
      // Repli hors-ligne (directive standing) — même patron que
      // PrescriptionProvider.loadPrescriptions (Module 5).
      final cached = await _offlineSync.getCachedReservations(patientId);
      if (cached.isNotEmpty) {
        _reservations = cached.map((row) => Reservation.fromJson(row)).toList();
        _isOffline = true;
        _error =
            'Hors connexion — dernières réservations synchronisées affichées (${_reservations.length}).';
      } else {
        _error = e.toString();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadReservation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedReservation = await _service.getReservation(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAvailableSlots({
    required String pharmacyId,
    required DateTime date,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _availableSlots = await _service.getAvailableTimeSlots(
        pharmacyId: pharmacyId,
        date: date,
      );
      _selectedPharmacyId = pharmacyId;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ==================== CART ====================

  void addToCart(ReservationItem item) {
    final existingIndex = _cartItems.indexWhere(
      (i) => i.productId == item.productId,
    );
    if (existingIndex != -1) {
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        quantity: _cartItems[existingIndex].quantity + item.quantity,
      );
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateCartItemQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // ==================== CHECKOUT ====================

  /// C243 : la réservation est créée par le serveur, qui retient les boîtes.
  /// Sans réseau, rien n'est mis en attente sur l'appareil : une réservation
  /// qui ne retient aucun stock ne garantit rien au patient.
  Future<Reservation?> createReservation({
    required String pharmacyId,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    _isOffline = false;
    notifyListeners();
    try {
      if (!await _offlineSync.hasInternet()) {
        _isOffline = true;
        throw const ReservationException(
          'Réservation impossible hors connexion. Reconnectez-vous pour '
          'réserver : vos produits sont retenus dès la confirmation.',
        );
      }
      final reservation = await _service.createReservation(
        pharmacyId: pharmacyId,
        items: _cartItems,
        notes: notes,
      );
      _selectedReservation = reservation;
      _reservations.add(reservation);
      _cartItems.clear();
      _queuePosition = reservation.queuePosition;
      _estimatedWaitMinutes = reservation.estimatedWaitMinutes;
      _isLoading = false;
      notifyListeners();
      return reservation;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== ACTIONS SUR RÉSERVATION ====================

  Future<bool> markAsReady(String id) async {
    try {
      final updated = await _service.markAsReady(id);
      _updateReservation(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelReservation(String id, {String? reason}) async {
    try {
      final updated = await _service.cancelReservation(id, reason: reason);
      _unavailableItems.remove(id);
      _updateReservation(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== RETRAIT (OFFICINE) ====================

  /// Charge la réservation et l'aperçu du retrait (prix du jour, ordonnance,
  /// produits qui ne peuvent plus être remis).
  Future<void> loadPickup(String id) async {
    _isLoading = true;
    _error = null;
    _pickupLines = [];
    notifyListeners();
    try {
      _selectedReservation = await _service.getReservation(id);
      _pickupLines = await _service.getPickupPreview(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Retrait : la réservation devient une vente au comptoir en espèces.
  /// Rend l'identifiant de la vente, ou `null` en cas de refus ([error]).
  Future<String?> pickUp(
    String id, {
    required String pickupCode,
    bool prescriptionChecked = false,
    bool allowPartial = false,
    String? partialReason,
  }) async {
    _error = null;
    try {
      final saleId = await _service.pickUp(
        id,
        pickupCode: pickupCode,
        prescriptionChecked: prescriptionChecked,
        allowPartial: allowPartial,
        partialReason: partialReason,
      );
      _unavailableItems.remove(id);
      _updateReservation(await _service.getReservation(id));
      return saleId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ==================== PHARMACY QUEUE ====================

  Future<void> refreshQueue(String pharmacyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final cacheKey = 'staff_queue_$pharmacyId';
    try {
      // C243 : expiration à l'usage, faite par le serveur ; les réservations
      // dépassées libèrent leurs boîtes avant l'affichage de la file.
      await _service.expireOverdueForPharmacy(pharmacyId);

      final reservations = await _service.getReservationsForPharmacy(
        pharmacyId,
      );
      // Bug corrigé (audit Module 6, 29/08/2026) : cette méthode ne
      // réassignait jamais `_reservations` — la file d'attente pharmacien
      // était toujours vide à l'écran.
      _reservations = reservations;
      _unavailableItems = await _service.getUnavailableItems(
        pharmacyId: pharmacyId,
      );
      _isOffline = false;
      unawaited(
        _offlineSync.cacheReservations(
          cacheKey,
          _reservations.map(_toCacheJson).toList(),
        ),
      );

      // Position dans la file, par ordre de réservation. C243 : calculée à
      // l'affichage, plus réécrite sur le serveur par l'application.
      final active = _reservations.where((r) => r.isActive).toList();
      for (int i = 0; i < active.length; i++) {
        final index = _reservations.indexWhere((r) => r.id == active[i].id);
        if (index != -1) {
          _reservations[index] = _reservations[index].copyWith(
            queuePosition: i + 1,
            estimatedWaitMinutes: 5 + i * 3,
          );
        }
      }
    } catch (e) {
      final cached = await _offlineSync.getCachedReservations(cacheKey);
      if (cached.isNotEmpty) {
        _reservations = cached.map((row) => Reservation.fromJson(row)).toList();
        _isOffline = true;
        _error =
            'Hors connexion — dernière file d\'attente synchronisée affichée.';
      } else {
        _error = e.toString();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  // ==================== UTILITAIRES ====================

  void selectSlot(TimeSlot slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void setPharmacyInfo({
    required String id,
    required String name,
    required String address,
    String? phone,
  }) {
    _selectedPharmacyId = id;
    _selectedPharmacyName = name;
    _selectedPharmacyAddress = address;
    _selectedPharmacyPhone = phone;
    notifyListeners();
  }

  void clearSelected() {
    _selectedReservation = null;
    _selectedSlot = null;
    _availableSlots = [];
    _queuePosition = null;
    _estimatedWaitMinutes = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _updateReservation(Reservation updated) {
    final index = _reservations.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _reservations[index] = updated;
    }
    if (_selectedReservation?.id == updated.id) {
      _selectedReservation = updated;
    }
    notifyListeners();
  }

  /// Données injectées par l'outil de captures d'écran
  /// (tool/screenshots) : les écrans sont montés hors ligne.
  @visibleForTesting
  void setStateForTesting({
    List<Reservation>? reservations,
    Reservation? selected,
    List<PickupLine>? pickupLines,
    Map<String, List<String>>? unavailableItems,
    List<ReservationItem>? cartItems,
  }) {
    if (reservations != null) _reservations = reservations;
    if (selected != null) _selectedReservation = selected;
    if (pickupLines != null) _pickupLines = pickupLines;
    if (unavailableItems != null) _unavailableItems = unavailableItems;
    if (cartItems != null) {
      _cartItems
        ..clear()
        ..addAll(cartItems);
    }
    _isLoading = false;
    _error = null;
    _isOffline = false;
    notifyListeners();
  }
}
