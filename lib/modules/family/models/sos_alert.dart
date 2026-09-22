import 'package:equatable/equatable.dart';

class SOSAlert extends Equatable {
  final String id;
  final String patientId;
  final String familyMemberId;
  final String alertType; // medical_emergency, accident, panic, location_share
  final String? message;
  final double? locationLat;
  final double? locationLon;
  final String status; // active, acknowledged, resolved
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const SOSAlert({
    required this.id,
    required this.patientId,
    required this.familyMemberId,
    required this.alertType,
    this.message,
    this.locationLat,
    this.locationLon,
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

  SOSAlert copyWith({
    String? id,
    String? patientId,
    String? familyMemberId,
    String? alertType,
    String? message,
    double? locationLat,
    double? locationLon,
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
    return SOSAlert(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      alertType: alertType ?? this.alertType,
      message: message ?? this.message,
      locationLat: locationLat ?? this.locationLat,
      locationLon: locationLon ?? this.locationLon,
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
    'patient_id': patientId,
    'family_member_id': familyMemberId,
    'alert_type': alertType,
    if (message != null) 'message': message,
    if (locationLat != null) 'location_lat': locationLat,
    if (locationLon != null) 'location_lon': locationLon,
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

  factory SOSAlert.fromJson(Map<String, dynamic> json) => SOSAlert(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    familyMemberId: json['family_member_id'] as String,
    alertType: json['alert_type'] as String,
    message: json['message'] as String?,
    locationLat: (json['location_lat'] as num?)?.toDouble(),
    locationLon: (json['location_lon'] as num?)?.toDouble(),
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
    patientId,
    familyMemberId,
    alertType,
    message,
    locationLat,
    locationLon,
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
    switch (alertType) {
      case 'medical_emergency':
        return '🚨 Urgence médicale';
      case 'accident':
        return '🚗 Accident';
      case 'panic':
        return '😰 Panique';
      case 'location_share':
        return '📍 Partage de position';
      default:
        return alertType;
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

  bool get isActive => status == 'active';
}
