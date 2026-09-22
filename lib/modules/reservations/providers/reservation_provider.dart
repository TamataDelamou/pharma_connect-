import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
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
  // offline » — même patron que PrescriptionProvider (Module 5) : en cas
  // d'échec réseau, on conserve les dernières données connues (cache local)
  // plutôt que de basculer sur un état d'erreur bloquant.
  bool _isOffline = false;

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

  int get cartTotal {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get hasItemsInCart => _cartItems.isNotEmpty;

  List<Reservation> get activeReservations {
    return _reservations
        .where(
          (r) =>
              r.status == ReservationStatus.pending ||
              r.status == ReservationStatus.confirmed ||
              r.status == ReservationStatus.ready,
        )
        .toList();
  }

  List<Reservation> get completedReservations {
    return _reservations
        .where(
          (r) =>
              r.status == ReservationStatus.pickedUp ||
              r.status == ReservationStatus.cancelled ||
              r.status == ReservationStatus.expired,
        )
        .toList();
  }

  // ==================== LOAD ====================

  /// items n'est jamais inclus dans Reservation.toJson() (table séparée) :
  /// même repli que PrescriptionProvider._toCacheJson (Module 5), pour ne
  /// pas faire revenir une réservation sans contenu de panier après un repli
  /// hors-ligne.
  Map<String, dynamic> _toCacheJson(Reservation r) => {
    ...r.toJson(),
    'reservation_items': r.items.map((i) => i.toJson(reservationId: r.id)).toList(),
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
      // RG-RES-02, best-effort et silencieux — voir
      // ReservationService.expireOverdueReservations.
      await _service.expireOverdueReservations();
      _reservations = await _service.getReservationsForPatient(patientId);
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

  Future<Reservation?> createReservation({
    required String patientId,
    required String patientName,
    required String patientPhone,
    String? patientEmail,
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyAddress,
    String? pharmacyPhone,
    DateTime? preferredPickupTime,
    String? deliveryAddress,
    String? paymentMethod,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    _isOffline = false;
    notifyListeners();
    try {
      Reservation reservation;
      if (await _offlineSync.hasInternet()) {
        try {
          reservation = await _service.createReservation(
            patientId: patientId,
            patientName: patientName,
            patientPhone: patientPhone,
            patientEmail: patientEmail,
            pharmacyId: pharmacyId,
            pharmacyName: pharmacyName,
            pharmacyAddress: pharmacyAddress,
            pharmacyPhone: pharmacyPhone,
            items: _cartItems,
            preferredPickupTime: preferredPickupTime,
            deliveryAddress: deliveryAddress,
            paymentMethod: paymentMethod,
            notes: notes,
          );
        } on StateError {
          // Refus métier réel (stock insuffisant, vérifié en ligne) — ne
          // jamais le masquer derrière une mise en file d'attente hors-ligne,
          // qui échouerait de la même façon (ou pire, réserverait à tort)
          // une fois synchronisée.
          rethrow;
        } catch (e) {
          // Le réseau semblait disponible (checkConnectivity) mais l'appel
          // Supabase a tout de même échoué (DNS, backend injoignable,
          // timeout) : même repli que l'absence de réseau ci-dessous.
          reservation = await _queueOfflineReservation(
            patientId: patientId,
            patientName: patientName,
            patientPhone: patientPhone,
            patientEmail: patientEmail,
            pharmacyId: pharmacyId,
            pharmacyName: pharmacyName,
            pharmacyAddress: pharmacyAddress,
            pharmacyPhone: pharmacyPhone,
            preferredPickupTime: preferredPickupTime,
            deliveryAddress: deliveryAddress,
            paymentMethod: paymentMethod,
            notes: notes,
          );
        }
      } else {
        reservation = await _queueOfflineReservation(
          patientId: patientId,
          patientName: patientName,
          patientPhone: patientPhone,
          patientEmail: patientEmail,
          pharmacyId: pharmacyId,
          pharmacyName: pharmacyName,
          pharmacyAddress: pharmacyAddress,
          pharmacyPhone: pharmacyPhone,
          preferredPickupTime: preferredPickupTime,
          deliveryAddress: deliveryAddress,
          paymentMethod: paymentMethod,
          notes: notes,
        );
      }
      _selectedReservation = reservation;
      _reservations.add(reservation);
      _cartItems.clear();
      _queuePosition = reservation.queuePosition;
      _estimatedWaitMinutes = reservation.estimatedWaitMinutes;
      _isLoading = false;
      notifyListeners();
      return reservation;
    } catch (e) {
      _error = e is StateError ? e.message : e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Directive standing « privilégier le mode hors-ligne » : la réservation
  /// est enregistrée localement et rejouée par OfflineSyncService.syncAll()
  /// dès le retour du réseau, même patron que
  /// PrescriptionProvider._queueOfflinePrescription (Module 5).
  ///
  /// Limite documentée (registre des écarts, item ajouté à la clôture de ce
  /// module) : contrairement à une création en ligne,
  /// StockService.reserveStock() n'est PAS appelé ici — c'est un appel
  /// réseau à part entière, qui ne peut pas être simplement mis en file
  /// d'attente comme un insert de données. Le stock n'est donc pas
  /// réellement bloqué tant que cette réservation n'a pas été synchronisée :
  /// deux patients hors-ligne réservant simultanément le même dernier
  /// exemplaire ne seront départagés qu'à la synchronisation (l'un des deux
  /// syncAll() échouera alors silencieusement côté "reservations", à
  /// réconcilier manuellement — aucun mécanisme de notification de ce cas
  /// n'existe aujourd'hui).
  Future<Reservation> _queueOfflineReservation({
    required String patientId,
    required String patientName,
    required String patientPhone,
    String? patientEmail,
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyAddress,
    String? pharmacyPhone,
    DateTime? preferredPickupTime,
    String? deliveryAddress,
    String? paymentMethod,
    String? notes,
  }) async {
    _isOffline = true;
    final id = const Uuid().v4();
    final now = DateTime.now();

    final reservation = Reservation(
      id: id,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      patientEmail: patientEmail,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      pharmacyAddress: pharmacyAddress,
      pharmacyPhone: pharmacyPhone,
      items: List.of(_cartItems),
      reservedAt: now,
      pickupTime: preferredPickupTime,
      pickupDeadline: now.add(const Duration(hours: 2)),
      status: ReservationStatus.pending,
      totalPrice: cartTotal,
      qrCodeToken: 'qr_${const Uuid().v4().substring(0, 8)}',
      notes: notes,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      queuePosition: null,
      estimatedWaitMinutes: null,
    );

    await _offlineSync.queueOperation(
      table: 'reservations',
      recordId: id,
      operation: 'insert',
      data: reservation.toJson(),
    );
    for (final item in reservation.items) {
      await _offlineSync.queueOperation(
        table: 'reservation_items',
        recordId: '${id}_${item.productId.isEmpty ? item.productName : item.productId}',
        operation: 'insert',
        data: item.toJson(reservationId: id),
      );
    }
    await _offlineSync.upsertCachedReservation(
      patientId,
      _toCacheJson(reservation),
    );
    return reservation;
  }

  // ==================== ACTIONS SUR RÉSERVATION ====================

  Future<bool> confirmReservation(String id) async {
    try {
      final updated = await _service.confirmReservation(id);
      _updateReservation(updated);
      _queuePosition = updated.queuePosition;
      _estimatedWaitMinutes = updated.estimatedWaitMinutes;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsReady(String id) async {
    try {
      final updated = await _service.markAsReady(id);
      _updateReservation(updated);
      _queuePosition = 0;
      _estimatedWaitMinutes = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsPickedUp(String id) async {
    try {
      final updated = await _service.markAsPickedUp(id);
      _updateReservation(updated);
      notifyListeners();
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
      _updateReservation(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== PHARMACY QUEUE ====================

  Future<void> refreshQueue(String pharmacyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final cacheKey = 'staff_queue_$pharmacyId';
    try {
      // RG-RES-02, best-effort et silencieux — voir
      // ReservationService.expireOverdueReservations.
      await _service.expireOverdueReservations(pharmacyId: pharmacyId);

      final reservations = await _service.getReservationsForPharmacy(
        pharmacyId,
      );
      // Bug corrigé (audit Module 6, 29/08/2026) : cette méthode ne
      // réassignait jamais `_reservations` — elle ne faisait que tenter de
      // patcher, par id, des entrées dans l'ancienne liste en mémoire
      // (peuplée uniquement par loadReservations/loadPatientReservations,
      // jamais appelées par pharmacy_queue_screen.dart). En pratique, la
      // file d'attente pharmacien était donc TOUJOURS vide à l'écran, quel
      // que soit le nombre réel de réservations en attente.
      _reservations = reservations;
      _isOffline = false;
      unawaited(
        _offlineSync.cacheReservations(
          cacheKey,
          _reservations.map(_toCacheJson).toList(),
        ),
      );

      final pending = _reservations
          .where(
            (r) =>
                r.status == ReservationStatus.pending ||
                r.status == ReservationStatus.confirmed,
          )
          .toList();

      // Mettre à jour les positions dans la file, et les persister côté
      // serveur (audit Module 6 : jusqu'ici recalculées seulement en
      // mémoire locale, jamais réécrites — voir
      // ReservationService.updateQueuePosition). Best-effort : un échec
      // isolé sur une ligne ne doit pas interrompre le rafraîchissement.
      for (int i = 0; i < pending.length; i++) {
        final index = _reservations.indexWhere((r) => r.id == pending[i].id);
        if (index != -1) {
          _reservations[index] = _reservations[index].copyWith(
            queuePosition: i + 1,
            estimatedWaitMinutes: 5 + i * 3,
          );
        }
        try {
          await _service.updateQueuePosition(
            pending[i].id,
            position: i + 1,
            estimatedWaitMinutes: 5 + i * 3,
          );
        } catch (_) {}
      }
      notifyListeners();
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
      notifyListeners();
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
}
