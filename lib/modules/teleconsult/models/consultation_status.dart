enum ConsultationStatus { pending, confirmed, completed, cancelled, missed }

extension ConsultationStatusExtension on ConsultationStatus {
  String get label {
    switch (this) {
      case ConsultationStatus.pending:
        return 'En attente';
      case ConsultationStatus.confirmed:
        return 'Confirmée';
      case ConsultationStatus.completed:
        return 'Terminée';
      case ConsultationStatus.cancelled:
        return 'Annulée';
      case ConsultationStatus.missed:
        return 'Non honorée';
    }
  }

  String get icon {
    switch (this) {
      case ConsultationStatus.pending:
        return '⏳';
      case ConsultationStatus.confirmed:
        return '✅';
      case ConsultationStatus.completed:
        return '📋';
      case ConsultationStatus.cancelled:
        return '❌';
      case ConsultationStatus.missed:
        return '⚠️';
    }
  }

  bool get isActive =>
      this == ConsultationStatus.pending ||
      this == ConsultationStatus.confirmed;
  bool get isPast =>
      this == ConsultationStatus.completed ||
      this == ConsultationStatus.missed ||
      this == ConsultationStatus.cancelled;
}
