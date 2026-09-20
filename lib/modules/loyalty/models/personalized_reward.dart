import 'package:equatable/equatable.dart';

class PersonalizedReward extends Equatable {
  final String id;
  final String patientId;
  final String rewardType; // discount, bonus_points, free_item, premium_access
  final String title;
  final String? description;
  final int? pointsCost;
  final int? discountPercentage;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const PersonalizedReward({
    required this.id,
    required this.patientId,
    required this.rewardType,
    required this.title,
    this.description,
    this.pointsCost,
    this.discountPercentage,
    this.isActive = true,
    this.expiresAt,
    this.usedAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  PersonalizedReward copyWith({
    String? id,
    String? patientId,
    String? rewardType,
    String? title,
    String? description,
    int? pointsCost,
    int? discountPercentage,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? usedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return PersonalizedReward(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      rewardType: rewardType ?? this.rewardType,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
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
    'reward_type': rewardType,
    'title': title,
    if (description != null) 'description': description,
    if (pointsCost != null) 'points_cost': pointsCost,
    if (discountPercentage != null) 'discount_percentage': discountPercentage,
    'is_active': isActive,
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    if (usedAt != null) 'used_at': usedAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory PersonalizedReward.fromJson(Map<String, dynamic> json) =>
      PersonalizedReward(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        rewardType: json['reward_type'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        pointsCost: json['points_cost'] as int?,
        discountPercentage: json['discount_percentage'] as int?,
        isActive: json['is_active'] as bool? ?? true,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        usedAt: json['used_at'] != null
            ? DateTime.parse(json['used_at'] as String)
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
    rewardType,
    title,
    description,
    pointsCost,
    discountPercentage,
    isActive,
    expiresAt,
    usedAt,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get typeLabel {
    switch (rewardType) {
      case 'discount':
        return '💰 Réduction';
      case 'bonus_points':
        return '⭐ Points bonus';
      case 'free_item':
        return '🎁 Produit gratuit';
      case 'premium_access':
        return '👑 Accès premium';
      default:
        return rewardType;
    }
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isAvailable => isActive && !isExpired && usedAt == null;
  bool get isUsed => usedAt != null;
}
