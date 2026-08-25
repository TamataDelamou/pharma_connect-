import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../models/reservation_item.dart';
import '../models/reservation_status.dart';
import '../models/timeslot.dart';
import '../services/reservation_service.dart';

class ReservationProvider extends ChangeNotifier {
  final ReservationService _service = ReservationService();

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

  Future<void> loadReservations({ReservationStatus? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reservations = await _service.getReservations(status: status);
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
      _reservations = await _service.getReservationsForPatient(patientId);
    } catch (e) {
      _error = e.toString();
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
    notifyListeners();
    try {
      final reservation = await _service.createReservation(
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
    try {
      final reservations = await _service.getReservationsForPharmacy(
        pharmacyId,
      );
      final pending = reservations
          .where(
            (r) =>
                r.status == ReservationStatus.pending ||
                r.status == ReservationStatus.confirmed,
          )
          .toList();

      // Mettre à jour les positions dans la file
      for (int i = 0; i < pending.length; i++) {
        final index = _reservations.indexWhere((r) => r.id == pending[i].id);
        if (index != -1) {
          _reservations[index] = _reservations[index].copyWith(
            queuePosition: i + 1,
            estimatedWaitMinutes: 5 + i * 3,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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
