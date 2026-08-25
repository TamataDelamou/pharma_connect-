enum DeliveryStatus {
  scheduled,
  preparing,
  inProgress,
  arrived,
  delivered,
  cancelled,
}

extension DeliveryStatusExtension on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.scheduled:
        return 'Programmée';
      case DeliveryStatus.preparing:
        return 'En préparation';
      case DeliveryStatus.inProgress:
        return 'En cours';
      case DeliveryStatus.arrived:
        return 'Arrivé';
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  String get icon {
    switch (this) {
      case DeliveryStatus.scheduled:
        return '📅';
      case DeliveryStatus.preparing:
        return '📦';
      case DeliveryStatus.inProgress:
        return '🚴';
      case DeliveryStatus.arrived:
        return '📍';
      case DeliveryStatus.delivered:
        return '✅';
      case DeliveryStatus.cancelled:
        return '❌';
    }
  }

  int get order {
    switch (this) {
      case DeliveryStatus.scheduled:
        return 0;
      case DeliveryStatus.preparing:
        return 1;
      case DeliveryStatus.inProgress:
        return 2;
      case DeliveryStatus.arrived:
        return 3;
      case DeliveryStatus.delivered:
        return 4;
      case DeliveryStatus.cancelled:
        return -1;
    }
  }
}
