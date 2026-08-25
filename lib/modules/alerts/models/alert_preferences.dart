import 'alert_type.dart';
import 'alert_severity.dart';

class AlertPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool inAppEnabled;
  final bool soundEnabled;
  final Map<AlertType, bool> typeEnabled;
  final Map<AlertSeverity, bool> severityEnabled;

  const AlertPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.inAppEnabled = true,
    this.soundEnabled = true,
    this.typeEnabled = const {},
    this.severityEnabled = const {
      AlertSeverity.critical: true,
      AlertSeverity.warning: true,
      AlertSeverity.info: true,
      AlertSeverity.success: true,
    },
  });

  AlertPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? inAppEnabled,
    bool? soundEnabled,
    Map<AlertType, bool>? typeEnabled,
    Map<AlertSeverity, bool>? severityEnabled,
  }) {
    return AlertPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      typeEnabled: typeEnabled ?? this.typeEnabled,
      severityEnabled: severityEnabled ?? this.severityEnabled,
    );
  }

  bool isTypeEnabled(AlertType type) {
    return typeEnabled[type] ?? true;
  }

  bool isSeverityEnabled(AlertSeverity severity) {
    return severityEnabled[severity] ?? true;
  }
}
