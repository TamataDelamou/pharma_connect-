import 'delivery.dart';
import 'delivery_status.dart';

class DeliveryRoute {
  final String id;
  final List<Delivery> deliveries;
  final String driverId;
  final DateTime date;
  final RouteStatus status;
  final List<RouteStop> stops;

  const DeliveryRoute({
    required this.id,
    required this.deliveries,
    required this.driverId,
    required this.date,
    required this.status,
    this.stops = const [],
  });

  factory DeliveryRoute.fromJson(Map<String, dynamic> json) => DeliveryRoute(
    id: json['id'] as String,
    deliveries: (json['deliveries'] as List<dynamic>? ?? [])
        .map((d) => Delivery.fromJson(d as Map<String, dynamic>))
        .toList(),
    driverId: json['driver_id'] as String,
    date: DateTime.parse(json['date'] as String),
    status: RouteStatus.values.byName(json['status'] as String),
    stops: (json['stops'] as List<dynamic>? ?? [])
        .map((s) => RouteStop.fromJson(s as Map<String, dynamic>))
        .toList(),
  );

  // deliveries est reconstruit depuis route_stops.delivery_id, pas une
  // colonne : jamais écrit ici.
  Map<String, dynamic> toJson() => {
    'id': id,
    'driver_id': driverId,
    'date': date.toIso8601String(),
    'status': status.name,
  };

  int get totalDeliveries => deliveries.length;
  int get completedDeliveries =>
      deliveries.where((d) => d.status == DeliveryStatus.delivered).length;

  double get completionRate {
    if (totalDeliveries == 0) return 0;
    return completedDeliveries / totalDeliveries;
  }

  Duration get estimatedDuration {
    // Simulation : 15 min par livraison
    return Duration(minutes: totalDeliveries * 15);
  }
}

class RouteStop {
  final String id;
  final String deliveryId;
  final double latitude;
  final double longitude;
  final String address;
  final int stopOrder;
  final bool isCompleted;

  const RouteStop({
    required this.id,
    required this.deliveryId,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.stopOrder,
    this.isCompleted = false,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
    id: json['id'] as String,
    deliveryId: json['delivery_id'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    address: json['address'] as String,
    stopOrder: json['stop_order'] as int,
    isCompleted: json['is_completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson({required String routeId}) => {
    'id': id,
    'route_id': routeId,
    'delivery_id': deliveryId,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'stop_order': stopOrder,
    'is_completed': isCompleted,
  };
}

enum RouteStatus { planned, inProgress, completed, cancelled }

extension RouteStatusExtension on RouteStatus {
  String get label {
    switch (this) {
      case RouteStatus.planned:
        return 'Planifiée';
      case RouteStatus.inProgress:
        return 'En cours';
      case RouteStatus.completed:
        return 'Terminée';
      case RouteStatus.cancelled:
        return 'Annulée';
    }
  }
}
