import 'package:equatable/equatable.dart';

class TemperatureReading extends Equatable {
  final String id;
  final String deviceId;
  final double temperature;
  final DateTime timestamp;
  final String unit;
  final bool isAlert;
  final DateTime createdAt;
  final String? gsgId;
  final String? gsgOrgId;

  const TemperatureReading({
    required this.id,
    required this.deviceId,
    required this.temperature,
    required this.timestamp,
    this.unit = '°C',
    this.isAlert = false,
    required this.createdAt,
    this.gsgId,
    this.gsgOrgId,
  });

  TemperatureReading copyWith({
    String? id,
    String? deviceId,
    double? temperature,
    DateTime? timestamp,
    String? unit,
    bool? isAlert,
    DateTime? createdAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return TemperatureReading(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      temperature: temperature ?? this.temperature,
      timestamp: timestamp ?? this.timestamp,
      unit: unit ?? this.unit,
      isAlert: isAlert ?? this.isAlert,
      createdAt: createdAt ?? this.createdAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_id': deviceId,
    'temperature': temperature,
    'timestamp': timestamp.toIso8601String(),
    'unit': unit,
    'is_alert': isAlert,
    'created_at': createdAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory TemperatureReading.fromJson(Map<String, dynamic> json) =>
      TemperatureReading(
        id: json['id'] as String,
        deviceId: json['device_id'] as String,
        temperature: (json['temperature'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        unit: json['unit'] as String? ?? '°C',
        isAlert: json['is_alert'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    deviceId,
    temperature,
    timestamp,
    unit,
    isAlert,
    createdAt,
    gsgId,
    gsgOrgId,
  ];
}
