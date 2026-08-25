import 'dart:math';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../models/delivery_driver.dart';
import '../models/delivery_proof.dart';
import '../models/delivery_route.dart';

class DeliveryService {
  static final List<Delivery> _deliveries = [];
  static final List<DeliveryDriver> _drivers = [];
  static final List<DeliveryRoute> _routes = [];
  static final Random _random = Random();

  // ==================== DONNÉES MOCKÉES ====================

  static final List<DeliveryDriver> _mockDrivers = [
    const DeliveryDriver(
      id: 'drv_001',
      name: 'Amadou Diallo',
      phone: '+224611111111',
      isAvailable: true,
      rating: 4.8,
      completedDeliveries: 145,
      vehicleType: 'Scooter',
      vehiclePlate: 'RC 1234',
      isColdChainCertified: true,
    ),
    const DeliveryDriver(
      id: 'drv_002',
      name: 'Mamadou Sow',
      phone: '+224622222222',
      isAvailable: true,
      rating: 4.5,
      completedDeliveries: 98,
      vehicleType: 'Vélo',
      vehiclePlate: 'RC 5678',
      isColdChainCertified: false,
    ),
    const DeliveryDriver(
      id: 'drv_003',
      name: 'Fatoumata Camara',
      phone: '+224633333333',
      isAvailable: false,
      rating: 4.9,
      completedDeliveries: 210,
      vehicleType: 'Moto',
      vehiclePlate: 'RC 9012',
      isColdChainCertified: true,
    ),
  ];

  static final List<Delivery> _mockDeliveries = [
    _createMockDelivery(
      id: 'del_001',
      patientName: 'Jean Dupont',
      address: '123 Rue de la République, Conakry',
      status: DeliveryStatus.inProgress,
      driver: _mockDrivers[0],
      estimatedTimeRemaining: 12,
    ),
    _createMockDelivery(
      id: 'del_002',
      patientName: 'Marie Konaté',
      address: '45 Avenue de l\'Indépendance, Conakry',
      status: DeliveryStatus.scheduled,
      driver: null,
      estimatedTimeRemaining: null,
    ),
    _createMockDelivery(
      id: 'del_003',
      patientName: 'Ibrahim Camara',
      address: '78 Boulevard du 28 Septembre, Conakry',
      status: DeliveryStatus.arrived,
      driver: _mockDrivers[1],
      estimatedTimeRemaining: 0,
    ),
    _createMockDelivery(
      id: 'del_004',
      patientName: 'Fatoumata Diallo',
      address: '12 Avenue de l\'Hôpital, Conakry',
      status: DeliveryStatus.delivered,
      driver: _mockDrivers[2],
      estimatedTimeRemaining: 0,
    ),
  ];

  static Delivery _createMockDelivery({
    required String id,
    required String patientName,
    required String address,
    required DeliveryStatus status,
    DeliveryDriver? driver,
    int? estimatedTimeRemaining,
  }) {
    final now = DateTime.now();
    final proof = status == DeliveryStatus.delivered
        ? DeliveryProof(
            signatureData: 'mock_signature',
            imageUrl: 'https://picsum.photos/200',
            confirmationCode: 'CONF${_random.nextInt(1000000)}',
            timestamp: now.subtract(const Duration(minutes: 30)),
            recipientName: patientName,
          )
        : null;

    return Delivery(
      id: id,
      reservationId: 'res_${_random.nextInt(1000)}',
      patientId: 'patient_${_random.nextInt(100)}',
      patientName: patientName,
      patientPhone:
          '+2246${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}',
      deliveryAddress: address,
      latitude: 9.5 + _random.nextDouble() * 0.05,
      longitude: -13.7 - _random.nextDouble() * 0.05,
      driver: driver,
      scheduledAt: now.add(Duration(hours: _random.nextInt(4) + 1)),
      status: status,
      isColdChainRequired: _random.nextBool(),
      isExpress: _random.nextBool(),
      trackingHistory: [
        'Livraison programmée',
        if (status != DeliveryStatus.scheduled) 'En cours de préparation',
        if (status == DeliveryStatus.inProgress) 'Livreur en route',
        if (status == DeliveryStatus.arrived) 'Arrivé sur place',
        if (status == DeliveryStatus.delivered) 'Livraison confirmée',
      ],
      proof: proof,
      estimatedTimeRemaining: estimatedTimeRemaining,
    );
  }

  static void _initMockData() {
    if (_deliveries.isEmpty) {
      _deliveries.addAll(_mockDeliveries);
    }
    if (_drivers.isEmpty) {
      _drivers.addAll(_mockDrivers);
    }
  }

  // ==================== MÉTHODES ====================

  Future<List<Delivery>> getDeliveries({DeliveryStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    if (status != null) {
      return _deliveries.where((d) => d.status == status).toList();
    }
    return _deliveries;
  }

  Future<List<Delivery>> getDeliveriesForDriver(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    return _deliveries.where((d) => d.driver?.id == driverId).toList();
  }

  Future<List<Delivery>> getDeliveriesForPatient(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    return _deliveries.where((d) => d.patientId == patientId).toList();
  }

  Future<Delivery> getDelivery(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _deliveries.firstWhere((d) => d.id == id);
  }

  Future<List<DeliveryDriver>> getAvailableDrivers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _drivers.where((d) => d.isAvailable).toList();
  }

  Future<DeliveryDriver?> getDriver(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _drivers.firstWhere((d) => d.id == id, orElse: () => _drivers[0]);
  }

  // ==================== PLANIFICATION ====================

  Future<DeliveryRoute> planRoute({
    required String driverId,
    required List<String> deliveryIds,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _initMockData();

    final deliveries = _deliveries
        .where((d) => deliveryIds.contains(d.id))
        .toList();

    final stops = <RouteStop>[];
    for (int i = 0; i < deliveries.length; i++) {
      stops.add(
        RouteStop(
          id: 'stop_${i + 1}',
          deliveryId: deliveries[i].id,
          latitude: deliveries[i].latitude ?? 9.5,
          longitude: deliveries[i].longitude ?? -13.7,
          address: deliveries[i].deliveryAddress,
          stopOrder: i + 1,
          isCompleted: false,
        ),
      );
    }

    final route = DeliveryRoute(
      id: 'route_${DateTime.now().millisecondsSinceEpoch}',
      deliveries: deliveries,
      driverId: driverId,
      date: date,
      status: RouteStatus.planned,
      stops: stops,
    );

    _routes.add(route);
    return route;
  }

  Future<DeliveryRoute?> getRoute(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _routes.firstWhere((r) => r.id == id, orElse: () => _routes.first);
  }

  Future<List<DeliveryRoute>> getRoutesForDriver(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _routes.where((r) => r.driverId == driverId).toList();
  }

  // ==================== ACTIONS ====================

  Future<Delivery> scheduleDelivery({
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
    double? latitude,
    double? longitude,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    final id = 'del_${DateTime.now().millisecondsSinceEpoch}';
    final delivery = Delivery(
      id: id,
      reservationId: reservationId,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      deliveryAddress: deliveryAddress,
      latitude: latitude,
      longitude: longitude,
      scheduledAt: scheduledAt,
      status: DeliveryStatus.scheduled,
      isExpress: isExpress,
      isColdChainRequired: isColdChainRequired,
      pickupPointId: pickupPointId,
      pickupPointName: pickupPointName,
      trackingHistory: ['Livraison programmée'],
    );

    _deliveries.add(delivery);
    return delivery;
  }

  Future<Delivery> assignDriver(String deliveryId, String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final driver = _drivers.firstWhere((d) => d.id == driverId);
    final updated = _deliveries[index].copyWith(
      driver: driver,
      status: DeliveryStatus.preparing,
      trackingHistory: [
        ..._deliveries[index].trackingHistory,
        'Livreur assigné : ${driver.name}',
      ],
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<Delivery> startDelivery(String deliveryId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final updated = _deliveries[index].copyWith(
      status: DeliveryStatus.inProgress,
      startedAt: DateTime.now(),
      estimatedTimeRemaining: 30 + _random.nextInt(20),
      trackingHistory: [
        ..._deliveries[index].trackingHistory,
        'Livraison en cours',
      ],
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<Delivery> updateLocation({
    required String deliveryId,
    required double latitude,
    required double longitude,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    // Simuler la mise à jour de la distance restante
    final remaining = _random.nextInt(15) + 5;
    final updated = _deliveries[index].copyWith(
      latitude: latitude,
      longitude: longitude,
      estimatedTimeRemaining: remaining,
      distanceToDestination: remaining * 0.5,
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<Delivery> markAsArrived(String deliveryId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final updated = _deliveries[index].copyWith(
      status: DeliveryStatus.arrived,
      arrivedAt: DateTime.now(),
      estimatedTimeRemaining: 0,
      trackingHistory: [
        ..._deliveries[index].trackingHistory,
        'Le livreur est arrivé sur place',
      ],
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<Delivery> completeDelivery({
    required String deliveryId,
    String? signatureData,
    String? imageUrl,
    String? confirmationCode,
    String? recipientName,
    String? recipientPhone,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final proof = DeliveryProof(
      signatureData: signatureData,
      imageUrl: imageUrl,
      confirmationCode: confirmationCode ?? 'CONF${_random.nextInt(1000000)}',
      timestamp: DateTime.now(),
      recipientName: recipientName ?? _deliveries[index].patientName,
      recipientPhone: recipientPhone ?? _deliveries[index].patientPhone,
      notes: notes,
    );

    final updated = _deliveries[index].copyWith(
      status: DeliveryStatus.delivered,
      deliveredAt: DateTime.now(),
      proof: proof,
      trackingHistory: [
        ..._deliveries[index].trackingHistory,
        'Livraison confirmée',
      ],
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<Delivery> cancelDelivery(String deliveryId, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final updated = _deliveries[index].copyWith(
      status: DeliveryStatus.cancelled,
      cancelledAt: DateTime.now(),
      notes: reason,
      trackingHistory: [
        ..._deliveries[index].trackingHistory,
        'Livraison annulée : ${reason ?? "Raison non spécifiée"}',
      ],
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<void> updateDriverLocation(
    String driverId,
    double lat,
    double lon,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _drivers.indexWhere((d) => d.id == driverId);
    if (index != -1) {
      _drivers[index] = _drivers[index].copyWith(
        currentLatitude: lat,
        currentLongitude: lon,
      );
    }
  }

  // ==================== NOTIFICATIONS ====================

  Future<void> sendProximityAlert(String deliveryId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simuler l'envoi d'une notification de proximité
    // Dans la vraie vie, on utiliserait flutter_local_notifications + Firebase Cloud Messaging
  }

  Future<void> sendStatusNotification(String deliveryId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simuler l'envoi d'une notification de changement de statut
  }
}
