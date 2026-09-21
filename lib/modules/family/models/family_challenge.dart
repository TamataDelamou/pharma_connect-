import 'package:equatable/equatable.dart';

class FamilyChallenge extends Equatable {
  final String id;
  final String familyLinkId;
  final String challengeType; // steps, water, fruits, meditation, consultations
  final int targetValue;
  final int progress;
  final String status; // active, completed, expired
  final DateTime? deadlineDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const FamilyChallenge({
    required this.id,
    required this.familyLinkId,
    required this.challengeType,
    required this.targetValue,
    this.progress = 0,
    this.status = 'active',
    this.deadlineDate,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  FamilyChallenge copyWith({
    String? id,
    String? familyLinkId,
    String? challengeType,
    int? targetValue,
    int? progress,
    String? status,
    DateTime? deadlineDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return FamilyChallenge(
      id: id ?? this.id,
      familyLinkId: familyLinkId ?? this.familyLinkId,
      challengeType: challengeType ?? this.challengeType,
      targetValue: targetValue ?? this.targetValue,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      deadlineDate: deadlineDate ?? this.deadlineDate,
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
    'family_link_id': familyLinkId,
    'challenge_type': challengeType,
    'target_value': targetValue,
    'progress': progress,
    'status': status,
    if (deadlineDate != null)
      'deadline_date': deadlineDate!.toIso8601String().split('T').first,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory FamilyChallenge.fromJson(Map<String, dynamic> json) =>
      FamilyChallenge(
        id: json['id'] as String,
        familyLinkId: json['family_link_id'] as String,
        challengeType: json['challenge_type'] as String,
        targetValue: json['target_value'] as int,
        progress: json['progress'] as int? ?? 0,
        status: json['status'] as String? ?? 'active',
        deadlineDate: json['deadline_date'] != null
            ? DateTime.parse(json['deadline_date'] as String)
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
    familyLinkId,
    challengeType,
    targetValue,
    progress,
    status,
    deadlineDate,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get typeLabel {
    switch (challengeType) {
      case 'steps':
        return '🚶 Pas';
      case 'water':
        return '💧 Eau';
      case 'fruits':
        return '🍎 Fruits';
      case 'meditation':
        return '🧘 Méditation';
      case 'consultations':
        return '🩺 Consultations';
      default:
        return challengeType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'En cours';
      case 'completed':
        return '✅ Terminé';
      case 'expired':
        return '⏰ Expiré';
      default:
        return status;
    }
  }

  double get progressPercentage => targetValue > 0 ? progress / targetValue : 0;
  bool get isCompleted => status == 'completed';
}
