import 'package:equatable/equatable.dart';

class IotAlert extends Equatable {
  final String id;
  final String deviceId;
  final String
  type; // temperature_high, temperature_low, humidity_high, battery_low, offline, motion
  final String message;
  final double? value;
  final double? threshold;
  final String status; // active, acknowledged, resolved
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const IotAlert({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.message,
    this.value,
    this.threshold,
    this.status = 'active',
    this.acknowledgedAt,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  IotAlert copyWith({
    String? id,
    String? deviceId,
    String? type,
    String? message,
    double? value,
    double? threshold,
    String? status,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return IotAlert(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      message: message ?? this.message,
      value: value ?? this.value,
      threshold: threshold ?? this.threshold,
      status: status ?? this.status,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
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
    'device_id': deviceId,
    'type': type,
    'message': message,
    if (value != null) 'value': value,
    if (threshold != null) 'threshold': threshold,
    'status': status,
    if (acknowledgedAt != null)
      'acknowledged_at': acknowledgedAt!.toIso8601String(),
    if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory IotAlert.fromJson(Map<String, dynamic> json) => IotAlert(
    id: json['id'] as String,
    deviceId: json['device_id'] as String,
    type: json['type'] as String,
    message: json['message'] as String,
    value: (json['value'] as num?)?.toDouble(),
    threshold: (json['threshold'] as num?)?.toDouble(),
    status: json['status'] as String? ?? 'active',
    acknowledgedAt: json['acknowledged_at'] != null
        ? DateTime.parse(json['acknowledged_at'] as String)
        : null,
    resolvedAt: json['resolved_at'] != null
        ? DateTime.parse(json['resolved_at'] as String)
        : null,
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
    deviceId,
    type,
    message,
    value,
    threshold,
    status,
    acknowledgedAt,
    resolvedAt,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get typeLabel {
    switch (type) {
      case 'temperature_high':
        return '🌡️ Température élevée';
      case 'temperature_low':
        return '🌡️ Température basse';
      case 'humidity_high':
        return '💧 Humidité élevée';
      case 'battery_low':
        return '🔋 Batterie faible';
      case 'offline':
        return '📡 Hors ligne';
      case 'motion':
        return '🚨 Mouvement détecté';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';
      case 'acknowledged':
        return 'Accusée';
      case 'resolved':
        return 'Résolue';
      default:
        return status;
    }
  }
}
