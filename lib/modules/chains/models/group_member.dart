import 'package:equatable/equatable.dart';

class GroupMember extends Equatable {
  final String id;
  final String groupId;
  final String pharmacyId;
  final String role; // admin, manager, staff, viewer
  final List<String> permissions;
  final DateTime joinedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? pharmacyName;
  final String? pharmacyAddress;
  final String? pharmacyCity;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.pharmacyId,
    required this.role,
    this.permissions = const [],
    required this.joinedAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.pharmacyName,
    this.pharmacyAddress,
    this.pharmacyCity,
  });

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? pharmacyId,
    String? role,
    List<String>? permissions,
    DateTime? joinedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? pharmacyName,
    String? pharmacyAddress,
    String? pharmacyCity,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyAddress: pharmacyAddress ?? this.pharmacyAddress,
      pharmacyCity: pharmacyCity ?? this.pharmacyCity,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'pharmacy_id': pharmacyId,
    'role': role,
    'permissions': permissions,
    'joined_at': joinedAt.toIso8601String(),
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
    id: json['id'] as String,
    groupId: json['group_id'] as String,
    pharmacyId: json['pharmacy_id'] as String,
    role: json['role'] as String,
    permissions: (json['permissions'] as List?)?.cast<String>() ?? [],
    joinedAt: DateTime.parse(json['joined_at'] as String),
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    pharmacyName: json['pharmacies'] != null
        ? (json['pharmacies'] as Map<String, dynamic>)['name'] as String?
        : null,
    pharmacyAddress: json['pharmacies'] != null
        ? (json['pharmacies'] as Map<String, dynamic>)['address'] as String?
        : null,
    pharmacyCity: json['pharmacies'] != null
        ? (json['pharmacies'] as Map<String, dynamic>)['city'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    groupId,
    pharmacyId,
    role,
    permissions,
    joinedAt,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    pharmacyName,
    pharmacyAddress,
    pharmacyCity,
  ];

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'manager':
        return 'Gestionnaire';
      case 'staff':
        return 'Personnel';
      case 'viewer':
        return 'Observateur';
      default:
        return role;
    }
  }
}
