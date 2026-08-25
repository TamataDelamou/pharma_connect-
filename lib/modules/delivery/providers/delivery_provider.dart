import 'package:flutter/material.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../models/delivery_driver.dart';
import '../services/delivery_service.dart';

class DeliveryProvider extends ChangeNotifier {
  final DeliveryService _service = DeliveryService();

  List<Delivery> _deliveries = [];
  Delivery? _selectedDelivery;
  List<DeliveryDriver> _availableDrivers = [];
  bool _isLoading = false;
  String? _error;

  List<Delivery> get deliveries => _deliveries;
  Delivery? get selectedDelivery => _selectedDelivery;
  List<DeliveryDriver> get availableDrivers => _availableDrivers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Delivery> get activeDeliveries {
    return _deliveries.where((d) => d.isActive).toList();
  }

  List<Delivery> get pastDeliveries {
    return _deliveries.where((d) => d.isPast).toList();
  }

  // ==================== LOAD ====================

  Future<void> loadDeliveries({DeliveryStatus? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _deliveries = await _service.getDeliveries(status: status);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDelivery(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedDelivery = await _service.getDelivery(id);
    } catch (e) {
      _error = e.toString();
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
      _error = e.toString();
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
      return false;
    }
  }

  Future<bool> completeDelivery({
    required String deliveryId,
    String? signatureData,
    String? imageUrl,
    String? confirmationCode,
    String? recipientName,
    String? recipientPhone,
    String? notes,
  }) async {
    try {
      final updated = await _service.completeDelivery(
        deliveryId: deliveryId,
        signatureData: signatureData,
        imageUrl: imageUrl,
        confirmationCode: confirmationCode,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        notes: notes,
      );
      _updateDelivery(updated);
      return true;
    } catch (e) {
      _error = e.toString();
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
      return false;
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
