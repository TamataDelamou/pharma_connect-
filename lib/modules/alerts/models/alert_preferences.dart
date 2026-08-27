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

  factory AlertPreferences.fromJson(Map<String, dynamic> json) {
    return AlertPreferences(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      inAppEnabled: json['in_app_enabled'] as bool? ?? true,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      typeEnabled: _decodeTypeMap(json['type_enabled'] as Map<String, dynamic>?),
      severityEnabled: _decodeSeverityMap(
        json['severity_enabled'] as Map<String, dynamic>?,
      ),
    );
  }

  static Map<AlertType, bool> _decodeTypeMap(Map<String, dynamic>? raw) {
    if (raw == null) return const {};
    return {
      for (final entry in raw.entries)
        AlertType.values.byName(entry.key): entry.value as bool,
    };
  }

  static Map<AlertSeverity, bool> _decodeSeverityMap(
    Map<String, dynamic>? raw,
  ) {
    if (raw == null) {
      return const {
        AlertSeverity.critical: true,
        AlertSeverity.warning: true,
        AlertSeverity.info: true,
        AlertSeverity.success: true,
      };
    }
    return {
      for (final entry in raw.entries)
        AlertSeverity.values.byName(entry.key): entry.value as bool,
    };
  }

  Map<String, dynamic> toJson() => {
    'push_enabled': pushEnabled,
    'email_enabled': emailEnabled,
    'in_app_enabled': inAppEnabled,
    'sound_enabled': soundEnabled,
    'type_enabled': {for (final e in typeEnabled.entries) e.key.name: e.value},
    'severity_enabled': {
      for (final e in severityEnabled.entries) e.key.name: e.value,
    },
  };

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
