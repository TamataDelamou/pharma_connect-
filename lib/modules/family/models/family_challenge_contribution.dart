import 'package:equatable/equatable.dart';

class FamilyChallengeContribution extends Equatable {
  final String id;
  final String challengeId;
  final String patientId;
  final int contributionValue;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? patientName;

  const FamilyChallengeContribution({
    required this.id,
    required this.challengeId,
    required this.patientId,
    this.contributionValue = 0,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
  });

  FamilyChallengeContribution copyWith({
    String? id,
    String? challengeId,
    String? patientId,
    int? contributionValue,
    DateTime? updatedAt,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
  }) {
    return FamilyChallengeContribution(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      patientId: patientId ?? this.patientId,
      contributionValue: contributionValue ?? this.contributionValue,
      updatedAt: updatedAt ?? this.updatedAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'challenge_id': challengeId,
    'patient_id': patientId,
    'contribution_value': contributionValue,
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory FamilyChallengeContribution.fromJson(Map<String, dynamic> json) =>
      FamilyChallengeContribution(
        id: json['id'] as String,
        challengeId: json['challenge_id'] as String,
        patientId: json['patient_id'] as String,
        contributionValue: json['contribution_value'] as int? ?? 0,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
        patientName: json['patients'] != null
            ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
            : null,
      );

  @override
  List<Object?> get props => [
    id,
    challengeId,
    patientId,
    contributionValue,
    updatedAt,
    gsgId,
    gsgOrgId,
    patientName,
  ];
}
