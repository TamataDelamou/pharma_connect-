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
