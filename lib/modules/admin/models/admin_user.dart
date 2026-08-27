import 'admin_role.dart';
import 'admin_permission.dart';

class AdminUser {
  final String id;
  final String userId;
  final String email;
  final String fullName;
  final String? phone;
  final AdminRole role;
  final List<AdminPermission> permissions;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? createdBy;
  final String? notes;

  AdminUser({
    required this.id,
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.permissions,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    this.lastLoginAt,
    this.createdBy,
    this.notes,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'] as String,
    userId: json['user_id'] as String? ?? '',
    email: json['email'] as String,
    fullName: json['full_name'] as String,
    phone: json['phone'] as String?,
    role: AdminRole.values.byName(json['role'] as String),
    permissions: (json['permissions'] as List<dynamic>? ?? [])
        .map((p) => AdminPermission.values.byName(p as String))
        .toList(),
    isActive: json['is_active'] as bool? ?? true,
    isVerified: json['is_verified'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    lastLoginAt: json['last_login_at'] != null
        ? DateTime.parse(json['last_login_at'] as String)
        : null,
    createdBy: json['created_by'] as String?,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId.isEmpty ? null : userId,
    'email': email,
    'full_name': fullName,
    'phone': phone,
    'role': role.name,
    'permissions': permissions.map((p) => p.name).toList(),
    'is_active': isActive,
    'is_verified': isVerified,
    'created_at': createdAt.toIso8601String(),
    'last_login_at': lastLoginAt?.toIso8601String(),
    'created_by': createdBy,
    'notes': notes,
  };

  AdminUser copyWith({
    String? id,
    String? userId,
    String? email,
    String? fullName,
    String? phone,
    AdminRole? role,
    List<AdminPermission>? permissions,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? createdBy,
    String? notes,
  }) {
    return AdminUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
    );
  }

  bool get isSuperAdmin => role == AdminRole.superAdmin;
  bool get canManageUsers =>
      role == AdminRole.superAdmin || role == AdminRole.admin;
  bool get canManagePharmacies =>
      role == AdminRole.superAdmin ||
      role == AdminRole.admin ||
      role == AdminRole.pharmacyManager;

  bool hasPermission(AdminPermission permission) {
    // Les super admins ont toutes les permissions
    if (isSuperAdmin) return true;
    return permissions.contains(permission);
  }
}
