import 'package:equatable/equatable.dart';

class IotDevice extends Equatable {
  final String id;
  final String? pharmacyId;
  final String deviceId;
  final String name;
  final String
  type; // temperature_sensor, humidity_sensor, cold_chain_monitor, stock_scanner, motion_sensor
  final String? model;
  final String? firmwareVersion;
  final String status; // active, inactive, maintenance, offline
  final DateTime? lastReadingAt;
  final int? lastBatteryLevel;
  final String? location;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const IotDevice({
    required this.id,
    this.pharmacyId,
    required this.deviceId,
    required this.name,
    required this.type,
    this.model,
    this.firmwareVersion,
    this.status = 'active',
    this.lastReadingAt,
    this.lastBatteryLevel,
    this.location,
    this.config = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  IotDevice copyWith({
    String? id,
    String? pharmacyId,
    String? deviceId,
    String? name,
    String? type,
    String? model,
    String? firmwareVersion,
    String? status,
    DateTime? lastReadingAt,
    int? lastBatteryLevel,
    String? location,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return IotDevice(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      type: type ?? this.type,
      model: model ?? this.model,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      status: status ?? this.status,
      lastReadingAt: lastReadingAt ?? this.lastReadingAt,
      lastBatteryLevel: lastBatteryLevel ?? this.lastBatteryLevel,
      location: location ?? this.location,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (pharmacyId != null) 'pharmacy_id': pharmacyId,
    'device_id': deviceId,
    'name': name,
    'type': type,
    if (model != null) 'model': model,
    if (firmwareVersion != null) 'firmware_version': firmwareVersion,
    'status': status,
    if (lastReadingAt != null)
      'last_reading_at': lastReadingAt!.toIso8601String(),
    if (lastBatteryLevel != null) 'last_battery_level': lastBatteryLevel,
    if (location != null) 'location': location,
    'config': config,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory IotDevice.fromJson(Map<String, dynamic> json) => IotDevice(
    id: json['id'] as String,
    pharmacyId: json['pharmacy_id'] as String?,
    deviceId: json['device_id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    model: json['model'] as String?,
    firmwareVersion: json['firmware_version'] as String?,
    status: json['status'] as String? ?? 'active',
    lastReadingAt: json['last_reading_at'] != null
        ? DateTime.parse(json['last_reading_at'] as String)
        : null,
    lastBatteryLevel: json['last_battery_level'] as int?,
    location: json['location'] as String?,
    config: json['config'] as Map<String, dynamic>? ?? {},
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    pharmacyId,
    deviceId,
    name,
    type,
    model,
    firmwareVersion,
    status,
    lastReadingAt,
    lastBatteryLevel,
    location,
    config,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'maintenance':
        return 'Maintenance';
      case 'offline':
        return 'Hors ligne';
      default:
        return status;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'temperature_sensor':
        return 'Capteur de température';
      case 'humidity_sensor':
        return 'Capteur d\'humidité';
      case 'cold_chain_monitor':
        return 'Moniteur chaîne du froid';
      case 'stock_scanner':
        return 'Scanner de stock';
      case 'motion_sensor':
        return 'Capteur de mouvement';
      default:
        return type;
    }
  }

  bool get isOnline => status == 'active';
  bool get needsMaintenance =>
      status == 'maintenance' ||
      (lastBatteryLevel != null && lastBatteryLevel! < 15);
}
