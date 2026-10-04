import 'record_type.dart';
import '../../../core/theme/palette.dart';

class TemperatureRecord {
  final String id;
  final String equipmentId;
  final double temperature;
  final double? minTemperature;
  final double? maxTemperature;
  final DateTime timestamp;
  final RecordType type;
  final String? recordedBy;
  final String? notes;
  final bool isAlert;
  final String? alertId;

  TemperatureRecord({
    required this.id,
    required this.equipmentId,
    required this.temperature,
    this.minTemperature,
    this.maxTemperature,
    required this.timestamp,
    required this.type,
    this.recordedBy,
    this.notes,
    this.isAlert = false,
    this.alertId,
  });

  factory TemperatureRecord.fromJson(Map<String, dynamic> json) =>
      TemperatureRecord(
        id: json['id'] as String,
        equipmentId: json['equipment_id'] as String,
        temperature: (json['temperature'] as num).toDouble(),
        minTemperature: (json['min_temperature'] as num?)?.toDouble(),
        maxTemperature: (json['max_temperature'] as num?)?.toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: RecordType.values.byName(json['type'] as String),
        recordedBy: json['recorded_by'] as String?,
        notes: json['notes'] as String?,
        isAlert: json['is_alert'] as bool? ?? false,
        alertId: json['alert_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'equipment_id': equipmentId,
    'temperature': temperature,
    'min_temperature': minTemperature,
    'max_temperature': maxTemperature,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'recorded_by': recordedBy,
    'notes': notes,
    'is_alert': isAlert,
    'alert_id': alertId,
  };

  TemperatureRecord copyWith({
    String? id,
    String? equipmentId,
    double? temperature,
    double? minTemperature,
    double? maxTemperature,
    DateTime? timestamp,
    RecordType? type,
    String? recordedBy,
    String? notes,
    bool? isAlert,
    String? alertId,
  }) {
    return TemperatureRecord(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      temperature: temperature ?? this.temperature,
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      recordedBy: recordedBy ?? this.recordedBy,
      notes: notes ?? this.notes,
      isAlert: isAlert ?? this.isAlert,
      alertId: alertId ?? this.alertId,
    );
  }

  String get status {
    if (minTemperature == null && maxTemperature == null) return 'Inconnu';
    if (temperature < minTemperature! || temperature > maxTemperature!) {
      return '⚠️ Rupture';
    }
    return '✅ Conforme';
  }

  ColorRole get statusColor {
    if (minTemperature == null && maxTemperature == null) {
      return ColorRole.textMuted;
    }
    if (temperature < minTemperature! || temperature > maxTemperature!) {
      return ColorRole.danger;
    }
    return ColorRole.success;
  }
}
