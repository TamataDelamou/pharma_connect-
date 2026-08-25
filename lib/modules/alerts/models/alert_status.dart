enum AlertStatus { new_, read, dismissed, actioned }

extension AlertStatusExtension on AlertStatus {
  String get label {
    switch (this) {
      case AlertStatus.new_:
        return 'Nouveau';
      case AlertStatus.read:
        return 'Lu';
      case AlertStatus.dismissed:
        return 'Ignoré';
      case AlertStatus.actioned:
        return 'Traité';
    }
  }
}
