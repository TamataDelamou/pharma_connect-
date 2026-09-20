import 'package:equatable/equatable.dart';

class LoyaltyBadge extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String category; // health, activity, social, special
  final int? pointsRequired;
  final String?
  requirementType; // steps, challenges, referrals, streak, consultations, prescriptions
  final int? requirementValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const LoyaltyBadge({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.category,
    this.pointsRequired,
    this.requirementType,
    this.requirementValue,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  LoyaltyBadge copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? category,
    int? pointsRequired,
    String? requirementType,
    int? requirementValue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return LoyaltyBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      requirementType: requirementType ?? this.requirementType,
      requirementValue: requirementValue ?? this.requirementValue,
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
    'icon': icon,
    'category': category,
    if (pointsRequired != null) 'points_required': pointsRequired,
    if (requirementType != null) 'requirement_type': requirementType,
    if (requirementValue != null) 'requirement_value': requirementValue,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory LoyaltyBadge.fromJson(Map<String, dynamic> json) => LoyaltyBadge(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    icon: json['icon'] as String,
    category: json['category'] as String,
    pointsRequired: json['points_required'] as int?,
    requirementType: json['requirement_type'] as String?,
    requirementValue: json['requirement_value'] as int?,
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
    icon,
    category,
    pointsRequired,
    requirementType,
    requirementValue,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get categoryLabel {
    switch (category) {
      case 'health':
        return 'Santé';
      case 'activity':
        return 'Activité';
      case 'social':
        return 'Social';
      case 'special':
        return 'Spécial';
      default:
        return category;
    }
  }

  String get requirementLabel {
    switch (requirementType) {
      case 'steps':
        return 'pas';
      case 'challenges':
        return 'défis';
      case 'referrals':
        return 'parrainages';
      case 'streak':
        return 'jours consécutifs';
      case 'consultations':
        return 'consultations';
      case 'prescriptions':
        return 'prescriptions';
      default:
        return '';
    }
  }
}
