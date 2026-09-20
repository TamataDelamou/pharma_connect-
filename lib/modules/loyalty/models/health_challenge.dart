import 'package:equatable/equatable.dart';

class HealthChallenge extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String type; // daily, weekly, monthly
  final String difficulty; // easy, medium, hard
  final int points;
  final Map<String, dynamic> requirements;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const HealthChallenge({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.difficulty = 'easy',
    this.points = 10,
    this.requirements = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  HealthChallenge copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    String? difficulty,
    int? points,
    Map<String, dynamic>? requirements,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return HealthChallenge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      requirements: requirements ?? this.requirements,
      isActive: isActive ?? this.isActive,
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
    'name': name,
    if (description != null) 'description': description,
    'type': type,
    'difficulty': difficulty,
    'points': points,
    'requirements': requirements,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory HealthChallenge.fromJson(Map<String, dynamic> json) =>
      HealthChallenge(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        type: json['type'] as String,
        difficulty: json['difficulty'] as String? ?? 'easy',
        points: json['points'] as int? ?? 10,
        requirements: json['requirements'] as Map<String, dynamic>? ?? {},
        isActive: json['is_active'] as bool? ?? true,
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
    name,
    description,
    type,
    difficulty,
    points,
    requirements,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':
        return '🟢 Facile';
      case 'medium':
        return '🟡 Moyen';
      case 'hard':
        return '🔴 Difficile';
      default:
        return difficulty;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      default:
        return type;
    }
  }

  int get target {
    return requirements['target'] as int? ?? 0;
  }

  String get unit {
    return requirements['unit'] as String? ?? '';
  }
}

class ChallengeProgress extends Equatable {
  final String id;
  final String patientId;
  final String challengeId;
  final int progress;
  final int target;
  final bool completed;
  final DateTime? completedAt;
  final int streak;
  final DateTime? lastActivityDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const ChallengeProgress({
    required this.id,
    required this.patientId,
    required this.challengeId,
    this.progress = 0,
    required this.target,
    this.completed = false,
    this.completedAt,
    this.streak = 0,
    this.lastActivityDate,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  ChallengeProgress copyWith({
    String? id,
    String? patientId,
    String? challengeId,
    int? progress,
    int? target,
    bool? completed,
    DateTime? completedAt,
    int? streak,
    DateTime? lastActivityDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return ChallengeProgress(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      challengeId: challengeId ?? this.challengeId,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      streak: streak ?? this.streak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
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
    'challenge_id': challengeId,
    'progress': progress,
    'target': target,
    'completed': completed,
    if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    'streak': streak,
    if (lastActivityDate != null)
      'last_activity_date': lastActivityDate!
          .toIso8601String()
          .split('T')
          .first,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) =>
      ChallengeProgress(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        challengeId: json['challenge_id'] as String,
        progress: json['progress'] as int? ?? 0,
        target: json['target'] as int,
        completed: json['completed'] as bool? ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        streak: json['streak'] as int? ?? 0,
        lastActivityDate: json['last_activity_date'] != null
            ? DateTime.parse(json['last_activity_date'] as String)
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
    challengeId,
    progress,
    target,
    completed,
    completedAt,
    streak,
    lastActivityDate,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  double get progressPercentage => target > 0 ? progress / target : 0;
  bool get isActive => !completed && progress < target;
}
