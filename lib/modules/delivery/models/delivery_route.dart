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
