import 'package:equatable/equatable.dart';

class FamilyActivity extends Equatable {
  final String id;
  final String familyLinkId;
  final String patientId;
  final String
  activityType; // walk, water, fruits, meditation, consultation, medication
  final double? value;
  final String? note;
  final DateTime recordedAt;
  final DateTime createdAt;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? patientName;

  const FamilyActivity({
    required this.id,
    required this.familyLinkId,
    required this.patientId,
    required this.activityType,
    this.value,
    this.note,
    required this.recordedAt,
    required this.createdAt,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
  });

  FamilyActivity copyWith({
    String? id,
    String? familyLinkId,
    String? patientId,
    String? activityType,
    double? value,
    String? note,
    DateTime? recordedAt,
    DateTime? createdAt,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
  }) {
    return FamilyActivity(
      id: id ?? this.id,
      familyLinkId: familyLinkId ?? this.familyLinkId,
      patientId: patientId ?? this.patientId,
      activityType: activityType ?? this.activityType,
      value: value ?? this.value,
      note: note ?? this.note,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_link_id': familyLinkId,
    'patient_id': patientId,
    'activity_type': activityType,
    if (value != null) 'value': value,
    if (note != null) 'note': note,
    'recorded_at': recordedAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory FamilyActivity.fromJson(Map<String, dynamic> json) => FamilyActivity(
    id: json['id'] as String,
    familyLinkId: json['family_link_id'] as String,
    patientId: json['patient_id'] as String,
    activityType: json['activity_type'] as String,
    value: (json['value'] as num?)?.toDouble(),
    note: json['note'] as String?,
    recordedAt: DateTime.parse(json['recorded_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    patientName: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    familyLinkId,
    patientId,
    activityType,
    value,
    note,
    recordedAt,
    createdAt,
    gsgId,
    gsgOrgId,
    patientName,
  ];

  String get typeLabel {
    switch (activityType) {
      case 'walk':
        return '🚶 Marche';
      case 'water':
        return '💧 Eau';
      case 'fruits':
        return '🍎 Fruits';
      case 'meditation':
        return '🧘 Méditation';
      case 'consultation':
        return '🩺 Consultation';
      case 'medication':
        return '💊 Médicament';
      default:
        return activityType;
    }
  }
}
