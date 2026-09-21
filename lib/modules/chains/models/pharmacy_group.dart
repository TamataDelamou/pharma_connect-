import 'package:equatable/equatable.dart';

class PharmacyGroup extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String? description;
  final String? logoUrl;
  final String? ownerId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgOrgId;
  final String? gsgId;

  // Derived
  final int? memberCount;
  final String? ownerName;

  const PharmacyGroup({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.logoUrl,
    this.ownerId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgOrgId,
    this.gsgId,
    this.memberCount,
    this.ownerName,
  });

  PharmacyGroup copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? logoUrl,
    String? ownerId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgOrgId,
    String? gsgId,
    int? memberCount,
    String? ownerName,
  }) {
    return PharmacyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      ownerId: ownerId ?? this.ownerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      gsgId: gsgId ?? this.gsgId,
      memberCount: memberCount ?? this.memberCount,
      ownerName: ownerName ?? this.ownerName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (code != null) 'code': code,
    if (description != null) 'description': description,
    if (logoUrl != null) 'logo_url': logoUrl,
    if (ownerId != null) 'owner_id': ownerId,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
    if (gsgId != null) 'gsg_id': gsgId,
  };

  factory PharmacyGroup.fromJson(Map<String, dynamic> json) => PharmacyGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String?,
    description: json['description'] as String?,
    logoUrl: json['logo_url'] as String?,
    ownerId: json['owner_id'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    gsgId: json['gsg_id'] as String?,
    memberCount: json['members'] != null
        ? (json['members'] as List).length
        : null,
    ownerName: json['owners'] != null
        ? (json['owners'] as Map<String, dynamic>)['full_name'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    description,
    logoUrl,
    ownerId,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgOrgId,
    gsgId,
    memberCount,
    ownerName,
  ];
}
