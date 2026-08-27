import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../models/delivery_driver.dart';
import '../models/delivery_proof.dart';
import '../models/delivery_route.dart';
import '../../../core/services/supabase_service.dart';

class DeliveryService {
  SupabaseClient get _client => SupabaseService().client;

  static const _deliverySelect =
      '*, driver:delivery_drivers(*), proof:delivery_proofs(*)';

  Future<List<Delivery>> getDeliveries({DeliveryStatus? status}) async {
    var query = _client.from('deliveries').select(_deliverySelect);
    if (status != null) {
      query = query.eq('status', status.name);
    }
    final rows = await query.order('scheduled_at', ascending: false);
    return rows.map((row) => Delivery.fromJson(row)).toList();
  }

  Future<List<Delivery>> getDeliveriesForDriver(String driverId) async {
    final rows = await _client
        .from('deliveries')
        .select(_deliverySelect)
        .eq('driver_id', driverId);
    return rows.map((row) => Delivery.fromJson(row)).toList();
  }

  Future<List<Delivery>> getDeliveriesForPatient(String patientId) async {
    final rows = await _client
        .from('deliveries')
        .select(_deliverySelect)
        .eq('patient_id', patientId);
    return rows.map((row) => Delivery.fromJson(row)).toList();
  }

  Future<Delivery> getDelivery(String id) async {
    final row = await _client
        .from('deliveries')
        .select(_deliverySelect)
        .eq('id', id)
        .single();
    return Delivery.fromJson(row);
  }

  Future<List<DeliveryDriver>> getAvailableDrivers() async {
    final rows = await _client
        .from('delivery_drivers')
        .select()
        .eq('is_available', true);
    return rows.map((row) => DeliveryDriver.fromJson(row)).toList();
  }

  Future<DeliveryDriver?> getDriver(String id) async {
    final row = await _client
        .from('delivery_drivers')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row != null ? DeliveryDriver.fromJson(row) : null;
  }

  // ==================== PLANIFICATION ====================

  Future<DeliveryRoute> planRoute({
    required String driverId,
    required List<String> deliveryIds,
    required DateTime date,
  }) async {
    final deliveries = await _client
        .from('deliveries')
        .select(_deliverySelect)
        .inFilter('id', deliveryIds);
    final deliveryList = deliveries
        .map((row) => Delivery.fromJson(row))
        .toList();

    final routeRow = await _client
        .from('delivery_routes')
        .insert({
          'id': const Uuid().v4(),
          'driver_id': driverId,
          'date': date.toIso8601String(),
          'status': RouteStatus.planned.name,
        })
        .select()
        .single();
    final routeId = routeRow['id'] as String;

    final stops = <RouteStop>[];
    for (int i = 0; i < deliveryList.length; i++) {
      stops.add(
        RouteStop(
          id: const Uuid().v4(),
          deliveryId: deliveryList[i].id,
          latitude: deliveryList[i].latitude ?? 9.5,
          longitude: deliveryList[i].longitude ?? -13.7,
          address: deliveryList[i].deliveryAddress,
          stopOrder: i + 1,
          isCompleted: false,
        ),
      );
    }

    if (stops.isNotEmpty) {
      await _client
          .from('route_stops')
          .insert(stops.map((s) => s.toJson(routeId: routeId)).toList());
    }

    return DeliveryRoute(
      id: routeId,
      deliveries: deliveryList,
      driverId: driverId,
      date: date,
      status: RouteStatus.planned,
      stops: stops,
    );
  }

  Future<DeliveryRoute?> getRoute(String id) async {
    final routeRow = await _client
        .from('delivery_routes')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (routeRow == null) return null;
    return _hydrateRoute(routeRow);
  }

  Future<List<DeliveryRoute>> getRoutesForDriver(String driverId) async {
    final rows = await _client
        .from('delivery_routes')
        .select()
        .eq('driver_id', driverId);
    final routes = <DeliveryRoute>[];
    for (final row in rows) {
      routes.add(await _hydrateRoute(row));
    }
    return routes;
  }

  Future<DeliveryRoute> _hydrateRoute(Map<String, dynamic> routeRow) async {
    final stopRows = await _client
        .from('route_stops')
        .select()
        .eq('route_id', routeRow['id'] as String)
        .order('stop_order');
    final stops = stopRows.map((row) => RouteStop.fromJson(row)).toList();

    final deliveryIds = stops.map((s) => s.deliveryId).toList();
    var deliveries = <Delivery>[];
    if (deliveryIds.isNotEmpty) {
      final deliveryRows = await _client
          .from('deliveries')
          .select(_deliverySelect)
          .inFilter('id', deliveryIds);
      deliveries = deliveryRows.map((row) => Delivery.fromJson(row)).toList();
    }

    return DeliveryRoute(
      id: routeRow['id'] as String,
      deliveries: deliveries,
      driverId: routeRow['driver_id'] as String,
      date: DateTime.parse(routeRow['date'] as String),
      status: RouteStatus.values.byName(routeRow['status'] as String),
      stops: stops,
    );
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
    final delivery = Delivery(
      id: const Uuid().v4(),
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
      trackingHistory: const ['Livraison programmée'],
    );

    final row = await _client
        .from('deliveries')
        .insert(delivery.toJson())
        .select(_deliverySelect)
        .single();
    return Delivery.fromJson(row);
  }

  Future<Delivery> assignDriver(String deliveryId, String driverId) async {
    final current = await getDelivery(deliveryId);
    final driver = await getDriver(driverId);
    if (driver == null) throw Exception('Driver not found');

    final row = await _client
        .from('deliveries')
        .update({
          'driver_id': driverId,
          'status': DeliveryStatus.preparing.name,
          'tracking_history': [
            ...current.trackingHistory,
            'Livreur assigné : ${driver.name}',
          ],
        })
        .eq('id', deliveryId)
        .select(_deliverySelect)
        .single();
    return Delivery.fromJson(row);
  }

  Future<Delivery> startDelivery(String deliveryId) async {
    final current = await getDelivery(deliveryId);

    final row = await _client
        .from('deliveries')
        .update({
          'status': DeliveryStatus.inProgress.name,
          'started_at': DateTime.now().toIso8601String(),
          'tracking_history': [
            ...current.trackingHistory,
            'Livraison en cours',
          ],
        })
        .eq('id', deliveryId)
        .select(_deliverySelect)
        .single();
    return Delivery.fromJson(row);
  }

  Future<Delivery> updateLocation({
    required String deliveryId,
    required double latitude,
    required double longitude,
  }) async {
    final row = await _client
        .from('deliveries')
        .update({'latitude': latitude, 'longitude': longitude})
        .eq('id', deliveryId)
        .select(_deliverySelect)
        .single();
    return Delivery.fromJson(row);
  }

  Future<Delivery> markAsArrived(String deliveryId) async {
    final current = await getDelivery(deliveryId);

    final row = await _client
        .from('deliveries')
        .update({
          'status': DeliveryStatus.arrived.name,
          'arrived_at': DateTime.now().toIso8601String(),
          'estimated_time_remaining': 0,
          'tracking_history': [
            ...current.trackingHistory,
            'Le livreur est arrivé sur place',
          ],
        })
        .eq('id', deliveryId)
        .select(_deliverySelect)
        .single();
    return Delivery.fromJson(row);
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
    final current = await getDelivery(deliveryId);

    final proof = DeliveryProof(
      signatureData: signatureData,
      imageUrl: imageUrl,
      confirmationCode: confirmationCode,
      timestamp: DateTime.now(),
      recipientName: recipientName ?? current.patientName,
      recipientPhone: recipientPhone ?? current.patientPhone,
      notes: notes,
    );
    await _client
        .from('delivery_proofs')
        .upsert(proof.toJson(deliveryId: deliveryId));

    final row = await _client
        .from('deliveries')
        .update({
          'status': DeliveryStatus.delivered.name,
          'delivered_at': DateTime.now().toIso8601String(),
          'tracking_history': [
            ...current.trackingHistory,
            'Livraison confirmée',
          ],
        })
        .eq('id', deliveryId)
        .select(_deliverySelect)
        .single();
    return Delivery.fromJson(row);
  }

  Future<Delivery> cancelDelivery(String deliveryId, {String? reason}) async {
    final current = await getDelivery(deliveryId);

    final row = await _client
        .from('deliveries')
        .update({
          'status': DeliveryStatus.cancelled.name,
          'cancelled_at': DateTime.now().toIso8601String(),
          'notes': reason,
          'tracking_history': [
            ...current.trackingHistory,
            'Livraison annulée : ${reason ?? "Raison non spécifiée"}',
          ],
        })
        .eq('id', deliveryId)
        .select(_deliverySelect)
        .single();
    return Delivery.fromJson(row);
  }

  Future<void> updateDriverLocation(
    String driverId,
    double lat,
    double lon,
  ) async {
    await _client
        .from('delivery_drivers')
        .update({'current_latitude': lat, 'current_longitude': lon})
        .eq('id', driverId);
  }

  // ==================== NOTIFICATIONS ====================

  Future<void> sendProximityAlert(String deliveryId) async {
    // Dans la vraie vie : flutter_local_notifications + Firebase Cloud
    // Messaging. Rien à persister ici.
  }

  Future<void> sendStatusNotification(String deliveryId) async {
    // Idem — voir AlertService.createAlert pour le patron de notification
    // persistée quand ce module sera relié aux alertes.
  }
}
