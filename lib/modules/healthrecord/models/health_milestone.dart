import 'package:equatable/equatable.dart';

class HealthMilestone extends Equatable {
  final String id;
  final String patientId;
  final String
  milestoneType; // blood_pressure, weight, cholesterol, glucose, exercise
  final String achievement;
  final DateTime achievedAt;
  final String? gsgId;
  final String? gsgOrgId;

  const HealthMilestone({
    required this.id,
    required this.patientId,
    required this.milestoneType,
    required this.achievement,
    required this.achievedAt,
    this.gsgId,
    this.gsgOrgId,
  });

  HealthMilestone copyWith({
    String? id,
    String? patientId,
    String? milestoneType,
    String? achievement,
    DateTime? achievedAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return HealthMilestone(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      milestoneType: milestoneType ?? this.milestoneType,
      achievement: achievement ?? this.achievement,
      achievedAt: achievedAt ?? this.achievedAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'milestone_type': milestoneType,
    'achievement': achievement,
    'achieved_at': achievedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory HealthMilestone.fromJson(Map<String, dynamic> json) =>
      HealthMilestone(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        milestoneType: json['milestone_type'] as String,
        achievement: json['achievement'] as String,
        achievedAt: DateTime.parse(json['achieved_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    patientId,
    milestoneType,
    achievement,
    achievedAt,
    gsgId,
    gsgOrgId,
  ];

  String get typeLabel {
    switch (milestoneType) {
      case 'blood_pressure':
        return '💓 Tension artérielle';
      case 'weight':
        return '⚖️ Poids';
      case 'cholesterol':
        return '🩸 Cholestérol';
      case 'glucose':
        return '🍬 Glycémie';
      case 'exercise':
        return '🏋️ Exercice';
      default:
        return milestoneType;
    }
  }
}
