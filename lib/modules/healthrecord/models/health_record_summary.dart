import 'package:equatable/equatable.dart';

class HealthRecordSummary extends Equatable {
  final String id;
  final String healthRecordId;
  final String summary;
  final Map<String, dynamic> structuredData;
  final List<Map<String, dynamic>> criticalPoints;
  final DateTime generatedAt;
  final DateTime? expiresAt;
  final String? createdBy;
  final String? gsgId;
  final String? gsgOrgId;

  const HealthRecordSummary({
    required this.id,
    required this.healthRecordId,
    required this.summary,
    this.structuredData = const {},
    this.criticalPoints = const [],
    required this.generatedAt,
    this.expiresAt,
    this.createdBy,
    this.gsgId,
    this.gsgOrgId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'health_record_id': healthRecordId,
    'summary': summary,
    'structured_data': structuredData,
    'critical_points': criticalPoints,
    'generated_at': generatedAt.toIso8601String(),
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory HealthRecordSummary.fromJson(Map<String, dynamic> json) =>
      HealthRecordSummary(
        id: json['id'] as String,
        healthRecordId: json['health_record_id'] as String,
        summary: json['summary'] as String,
        structuredData: json['structured_data'] as Map<String, dynamic>? ?? {},
        criticalPoints:
            (json['critical_points'] as List?)?.cast<Map<String, dynamic>>() ??
            [],
        generatedAt: DateTime.parse(json['generated_at'] as String),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        createdBy: json['created_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    healthRecordId,
    summary,
    structuredData,
    criticalPoints,
    generatedAt,
    expiresAt,
    createdBy,
    gsgId,
    gsgOrgId,
  ];
}
