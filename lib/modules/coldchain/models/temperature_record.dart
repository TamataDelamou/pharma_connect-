import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'record_type.dart';

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

  Color get statusColor {
    if (minTemperature == null && maxTemperature == null) {
      return PharmaConnectColors.neutralMuted;
    }
    if (temperature < minTemperature! || temperature > maxTemperature!) {
      return PharmaConnectColors.accentRed;
    }
    return PharmaConnectColors.accentGreen;
  }
}
