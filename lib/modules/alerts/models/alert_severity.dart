enum AlertSeverity { critical, warning, info, success }

extension AlertSeverityExtension on AlertSeverity {
  String get label {
    switch (this) {
      case AlertSeverity.critical:
        return 'Critique';
      case AlertSeverity.warning:
        return 'Avertissement';
      case AlertSeverity.info:
        return 'Information';
      case AlertSeverity.success:
        return 'Succès';
    }
  }
}
