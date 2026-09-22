import 'package:equatable/equatable.dart';

class NetworkAdminRole extends Equatable {
  final String id;
  final String userId;
  final String role; // super_admin, network_admin, pharmacy_manager, viewer
  final String? pharmacyGroupId;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const NetworkAdminRole({
    required this.id,
    required this.userId,
    required this.role,
    this.pharmacyGroupId,
    this.permissions = const [],
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  NetworkAdminRole copyWith({
    String? id,
    String? userId,
    String? role,
    String? pharmacyGroupId,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return NetworkAdminRole(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      pharmacyGroupId: pharmacyGroupId ?? this.pharmacyGroupId,
      permissions: permissions ?? this.permissions,
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
    'user_id': userId,
    'role': role,
    if (pharmacyGroupId != null) 'pharmacy_group_id': pharmacyGroupId,
    'permissions': permissions,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory NetworkAdminRole.fromJson(Map<String, dynamic> json) =>
      NetworkAdminRole(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        role: json['role'] as String,
        pharmacyGroupId: json['pharmacy_group_id'] as String?,
        permissions: (json['permissions'] as List?)?.cast<String>() ?? [],
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
    userId,
    role,
    pharmacyGroupId,
    permissions,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get roleLabel {
    switch (role) {
      case 'super_admin':
        return '👑 Super Administrateur';
      case 'network_admin':
        return '🌐 Administrateur réseau';
      case 'pharmacy_manager':
        return '🏥 Gestionnaire d\'officine';
      case 'viewer':
        return '👁️ Observateur';
      default:
        return role;
    }
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isNetworkAdmin => role == 'network_admin' || role == 'super_admin';
  bool get isManager => role == 'pharmacy_manager' || isNetworkAdmin;
}
