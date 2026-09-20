import 'package:equatable/equatable.dart';

class PatientBadge extends Equatable {
  final String id;
  final String patientId;
  final String badgeId;
  final DateTime earnedAt;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived fields (from join)
  final String? badgeName;
  final String? badgeIcon;
  final String? badgeCategory;
  final String? badgeDescription;

  const PatientBadge({
    required this.id,
    required this.patientId,
    required this.badgeId,
    required this.earnedAt,
    this.gsgId,
    this.gsgOrgId,
    this.badgeName,
    this.badgeIcon,
    this.badgeCategory,
    this.badgeDescription,
  });

  PatientBadge copyWith({
    String? id,
    String? patientId,
    String? badgeId,
    DateTime? earnedAt,
    String? gsgId,
    String? gsgOrgId,
    String? badgeName,
    String? badgeIcon,
    String? badgeCategory,
    String? badgeDescription,
  }) {
    return PatientBadge(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      badgeId: badgeId ?? this.badgeId,
      earnedAt: earnedAt ?? this.earnedAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      badgeName: badgeName ?? this.badgeName,
      badgeIcon: badgeIcon ?? this.badgeIcon,
      badgeCategory: badgeCategory ?? this.badgeCategory,
      badgeDescription: badgeDescription ?? this.badgeDescription,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'badge_id': badgeId,
    'earned_at': earnedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory PatientBadge.fromJson(Map<String, dynamic> json) => PatientBadge(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    badgeId: json['badge_id'] as String,
    earnedAt: DateTime.parse(json['earned_at'] as String),
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    badgeName: json['badges'] != null
        ? (json['badges'] as Map<String, dynamic>)['name'] as String?
        : null,
    badgeIcon: json['badges'] != null
        ? (json['badges'] as Map<String, dynamic>)['icon'] as String?
        : null,
    badgeCategory: json['badges'] != null
        ? (json['badges'] as Map<String, dynamic>)['category'] as String?
        : null,
    badgeDescription: json['badges'] != null
        ? (json['badges'] as Map<String, dynamic>)['description'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    badgeId,
    earnedAt,
    gsgId,
    gsgOrgId,
    badgeName,
    badgeIcon,
    badgeCategory,
    badgeDescription,
  ];
}
