enum ReservationStatus {
  pending,
  confirmed,
  ready,
  pickedUp,
  cancelled,
  expired,
}

extension ReservationStatusExtension on ReservationStatus {
  String get label {
    switch (this) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.ready:
        return 'Prête';
      case ReservationStatus.pickedUp:
        return 'Retirée';
      case ReservationStatus.cancelled:
        return 'Annulée';
      case ReservationStatus.expired:
        return 'Expirée';
    }
  }

  String get icon {
    switch (this) {
      case ReservationStatus.pending:
        return '⏳';
      case ReservationStatus.confirmed:
        return '✅';
      case ReservationStatus.ready:
        return '📦';
      case ReservationStatus.pickedUp:
        return '🙌';
      case ReservationStatus.cancelled:
        return '❌';
      case ReservationStatus.expired:
        return '⏰';
    }
  }
}
