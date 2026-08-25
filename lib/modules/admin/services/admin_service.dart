import 'dart:math';
import '../models/admin_user.dart';
import '../models/admin_role.dart';
import '../models/admin_permission.dart';
import '../models/admin_pharmacy.dart';
import '../models/pharmacy_status.dart';
import '../models/audit_log.dart';
import '../models/system_config.dart';
import '../../../core/utils/currency_formatter.dart';

class AdminService {
  static final List<AdminUser> _users = [];
  static final List<AdminPharmacy> _pharmacies = [];
  static final List<AuditLog> _auditLogs = [];
  static final List<SystemConfig> _configs = [];
  static final Random _random = Random();
  static int _counter = 0;

  // ==================== DONNÉES MOCKÉES ====================

  static final List<AdminUser> _mockUsers = [
    AdminUser(
      id: 'au_001',
      userId: 'user_001',
      email: 'admin@pharmaconnect.com',
      fullName: 'Super Admin',
      role: AdminRole.superAdmin,
      permissions: AdminPermission.values,
      isActive: true,
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastLoginAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AdminUser(
      id: 'au_002',
      userId: 'user_002',
      email: 'pharmacien@pharmacie.fr',
      fullName: 'Dr. Martin',
      phone: '+224612345678',
      role: AdminRole.pharmacyManager,
      permissions: [
        AdminPermission.pharmacyRead,
        AdminPermission.pharmacyUpdate,
        AdminPermission.userRead,
        AdminPermission.reportView,
      ],
      isActive: true,
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AdminUser(
      id: 'au_003',
      userId: 'user_003',
      email: 'regulateur@dnpm.gouv.fr',
      fullName: 'M. Diallo',
      role: AdminRole.regulator,
      permissions: [
        AdminPermission.pharmacyRead,
        AdminPermission.licenseView,
        AdminPermission.licenseVerify,
        AdminPermission.reportView,
        AdminPermission.auditRead,
      ],
      isActive: true,
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
  ];

  static final List<AdminPharmacy> _mockPharmacies = [
    AdminPharmacy(
      id: 'ph_001',
      name: 'Pharmacie Centrale',
      address: '123 Avenue de la République, Conakry',
      phone: '+224612345678',
      email: 'contact@pharmaciecentrale.com',
      licenseNumber: 'DNPM-2024-001',
      status: PharmacyStatus.active,
      licenseExpiryDate: DateTime.now().add(const Duration(days: 365)),
      managerId: 'user_002',
      managerName: 'Dr. Martin',
      latitude: 9.5095,
      longitude: -13.7122,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      licenseVerifiedAt: DateTime.now().subtract(const Duration(days: 150)),
    ),
    AdminPharmacy(
      id: 'ph_002',
      name: 'Pharmacie du Soleil',
      address: '45 Rue du Commerce, Conakry',
      phone: '+224622334455',
      email: 'contact@pharmaciedusoleil.com',
      licenseNumber: 'DNPM-2024-002',
      status: PharmacyStatus.pending,
      managerId: 'user_004',
      managerName: 'Dr. Camara',
      latitude: 9.5195,
      longitude: -13.7222,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    AdminPharmacy(
      id: 'ph_003',
      name: 'Pharmacie de l\'Hôpital',
      address: 'Avenue de l\'Hôpital, Conakry',
      phone: '+224633445566',
      email: 'contact@pharmaciehopital.com',
      licenseNumber: 'DNPM-2024-003',
      status: PharmacyStatus.underReview,
      managerId: 'user_005',
      managerName: 'Dr. Sow',
      latitude: 9.4995,
      longitude: -13.7022,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  static final List<SystemConfig> _mockConfigs = [
    SystemConfig(
      id: 'cfg_001',
      key: 'default_currency',
      value: CurrencyFormatter.defaultCurrencyCode,
      category: 'general',
      description: 'Devise par défaut du système',
      isEditable: true,
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedBy: 'admin',
    ),
    SystemConfig(
      id: 'cfg_002',
      key: 'default_country',
      value: 'Guinée',
      category: 'general',
      description: 'Pays par défaut du système',
      isEditable: true,
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedBy: 'admin',
    ),
    SystemConfig(
      id: 'cfg_003',
      key: 'enable_2fa',
      value: 'true',
      category: 'security',
      description: 'Activer l\'authentification à deux facteurs',
      isEditable: true,
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedBy: 'admin',
    ),
    SystemConfig(
      id: 'cfg_004',
      key: 'max_login_attempts',
      value: '5',
      category: 'security',
      description: 'Nombre maximum de tentatives de connexion',
      isEditable: true,
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedBy: 'admin',
    ),
  ];

  static void _initMockData() {
    if (_users.isEmpty) {
      _users.addAll(_mockUsers);
      _counter = _users.length;
    }
    if (_pharmacies.isEmpty) {
      _pharmacies.addAll(_mockPharmacies);
    }
    if (_configs.isEmpty) {
      _configs.addAll(_mockConfigs);
    }
  }

  // ==================== UTILISATEURS ====================

  Future<List<AdminUser>> getUsers({
    AdminRole? role,
    bool? isActive,
    bool? isVerified,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var list = _users;

    if (role != null) {
      list = list.where((u) => u.role == role).toList();
    }

    if (isActive != null) {
      list = list.where((u) => u.isActive == isActive).toList();
    }

    if (isVerified != null) {
      list = list.where((u) => u.isVerified == isVerified).toList();
    }

    return list;
  }

  Future<AdminUser> getUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _users.firstWhere((u) => u.id == id);
  }

  Future<AdminUser> createUser({
    required String userId,
    required String email,
    required String fullName,
    required AdminRole role,
    List<AdminPermission>? permissions,
    String? phone,
    String? createdBy,
    String? notes,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    final user = AdminUser(
      id: 'au_${(++_counter).toString().padLeft(3, '0')}',
      userId: userId,
      email: email,
      fullName: fullName,
      phone: phone,
      role: role,
      permissions: permissions ?? _getDefaultPermissions(role),
      isActive: true,
      isVerified: false,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      notes: notes,
    );

    _users.add(user);

    // Log l'action
    await logAction(
      userId: createdBy ?? 'system',
      userName: 'System',
      action: 'create_user',
      resource: 'user',
      resourceId: user.id,
    );

    return user;
  }

  List<AdminPermission> _getDefaultPermissions(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return AdminPermission.values;
      case AdminRole.admin:
        return [
          AdminPermission.userRead,
          AdminPermission.userUpdate,
          AdminPermission.userActivate,
          AdminPermission.userDeactivate,
          AdminPermission.pharmacyRead,
          AdminPermission.pharmacyUpdate,
          AdminPermission.licenseView,
          AdminPermission.auditRead,
          AdminPermission.reportView,
        ];
      case AdminRole.pharmacyManager:
        return [
          AdminPermission.pharmacyRead,
          AdminPermission.pharmacyUpdate,
          AdminPermission.userRead,
          AdminPermission.reportView,
        ];
      case AdminRole.regulator:
        return [
          AdminPermission.pharmacyRead,
          AdminPermission.licenseView,
          AdminPermission.licenseVerify,
          AdminPermission.reportView,
          AdminPermission.auditRead,
        ];
      case AdminRole.auditor:
        return [
          AdminPermission.auditRead,
          AdminPermission.auditExport,
          AdminPermission.reportView,
        ];
      case AdminRole.support:
        return [
          AdminPermission.supportView,
          AdminPermission.supportCreate,
          AdminPermission.supportUpdate,
          AdminPermission.userRead,
        ];
      case AdminRole.viewer:
        return [
          AdminPermission.userRead,
          AdminPermission.pharmacyRead,
          AdminPermission.reportView,
        ];
    }
  }

  Future<AdminUser> updateUser(String id, AdminUser updated) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) throw Exception('User not found');

    _users[index] = updated;

    await logAction(
      userId: updated.createdBy ?? 'system',
      userName: 'System',
      action: 'update_user',
      resource: 'user',
      resourceId: id,
    );

    return _users[index];
  }

  Future<AdminUser> toggleUserActive(String id, bool isActive) async {
    final user = await getUser(id);
    final updated = user.copyWith(isActive: isActive);
    return updateUser(id, updated);
  }

  Future<AdminUser> verifyUser(String id) async {
    final user = await getUser(id);
    final updated = user.copyWith(isVerified: true);
    return updateUser(id, updated);
  }

  // ==================== PHARMACIES ====================

  Future<List<AdminPharmacy>> getPharmacies({
    PharmacyStatus? status,
    String? groupId,
    bool? isActive,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var list = _pharmacies;

    if (status != null) {
      list = list.where((p) => p.status == status).toList();
    }

    if (groupId != null) {
      list = list.where((p) => p.groupId == groupId).toList();
    }

    if (isActive != null) {
      list = list.where((p) => p.isActive == isActive).toList();
    }

    return list;
  }

  Future<AdminPharmacy> getPharmacy(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _pharmacies.firstWhere((p) => p.id == id);
  }

  Future<AdminPharmacy> createPharmacy({
    required String name,
    required String address,
    required String phone,
    required String email,
    String? licenseNumber,
    String? managerId,
    String? managerName,
    required double latitude,
    required double longitude,
    String? groupId,
    String? groupName,
    String? notes,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    final pharmacy = AdminPharmacy(
      id: 'ph_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      address: address,
      phone: phone,
      email: email,
      licenseNumber: licenseNumber,
      status: PharmacyStatus.pending,
      managerId: managerId,
      managerName: managerName,
      latitude: latitude,
      longitude: longitude,
      groupId: groupId,
      groupName: groupName,
      isActive: true,
      createdAt: DateTime.now(),
      notes: notes,
    );

    _pharmacies.add(pharmacy);

    await logAction(
      userId: 'system',
      userName: 'System',
      action: 'create_pharmacy',
      resource: 'pharmacy',
      resourceId: pharmacy.id,
    );

    return pharmacy;
  }

  Future<AdminPharmacy> updatePharmacy(String id, AdminPharmacy updated) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final index = _pharmacies.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Pharmacy not found');

    _pharmacies[index] = updated.copyWith(statusUpdatedAt: DateTime.now());

    await logAction(
      userId: 'system',
      userName: 'System',
      action: 'update_pharmacy',
      resource: 'pharmacy',
      resourceId: id,
    );

    return _pharmacies[index];
  }

  Future<AdminPharmacy> updatePharmacyStatus(
    String id,
    PharmacyStatus status,
  ) async {
    final pharmacy = await getPharmacy(id);
    final updated = pharmacy.copyWith(status: status);
    return updatePharmacy(id, updated);
  }

  Future<AdminPharmacy> verifyPharmacy(String id) async {
    final pharmacy = await getPharmacy(id);
    final updated = pharmacy.copyWith(
      status: PharmacyStatus.verified,
      licenseVerifiedAt: DateTime.now(),
    );
    return updatePharmacy(id, updated);
  }

  Future<AdminPharmacy> approvePharmacy(String id) async {
    final pharmacy = await getPharmacy(id);
    final updated = pharmacy.copyWith(
      status: PharmacyStatus.active,
      licenseVerifiedAt: DateTime.now(),
    );
    return updatePharmacy(id, updated);
  }

  // ==================== AUDIT ====================

  Future<void> logAction({
    required String userId,
    required String userName,
    required String action,
    required String resource,
    required String resourceId,
    Map<String, dynamic>? changes,
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    final log = AuditLog(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      action: action,
      resource: resource,
      resourceId: resourceId,
      changes: changes,
      ipAddress: '127.0.0.1',
      userAgent: 'Admin Backend',
      timestamp: DateTime.now(),
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );

    _auditLogs.add(log);
  }

  Future<List<AuditLog>> getAuditLogs({
    String? userId,
    String? resource,
    String? resourceId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var list = _auditLogs;

    if (userId != null) {
      list = list.where((l) => l.userId == userId).toList();
    }

    if (resource != null) {
      list = list.where((l) => l.resource == resource).toList();
    }

    if (resourceId != null) {
      list = list.where((l) => l.resourceId == resourceId).toList();
    }

    if (fromDate != null) {
      list = list.where((l) => l.timestamp.isAfter(fromDate)).toList();
    }

    if (toDate != null) {
      list = list.where((l) => l.timestamp.isBefore(toDate)).toList();
    }

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(limit).toList();
  }

  // ==================== CONFIGURATION ====================

  Future<List<SystemConfig>> getConfigs({String? category}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();

    var list = _configs;
    if (category != null) {
      list = list.where((c) => c.category == category).toList();
    }
    return list;
  }

  Future<SystemConfig> getConfig(String key) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _configs.firstWhere((c) => c.key == key);
  }

  Future<SystemConfig> updateConfig(
    String key,
    String value,
    String updatedBy,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final index = _configs.indexWhere((c) => c.key == key);
    if (index == -1) throw Exception('Config not found');

    final updated = _configs[index].copyWith(
      value: value,
      updatedAt: DateTime.now(),
      updatedBy: updatedBy,
    );

    _configs[index] = updated;

    await logAction(
      userId: updatedBy,
      userName: updatedBy,
      action: 'update_config',
      resource: 'config',
      resourceId: key,
    );

    return updated;
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getStatistics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    return {
      'totalUsers': _users.length,
      'activeUsers': _users.where((u) => u.isActive).length,
      'verifiedUsers': _users.where((u) => u.isVerified).length,
      'totalPharmacies': _pharmacies.length,
      'pendingPharmacies': _pharmacies
          .where((p) => p.status == PharmacyStatus.pending)
          .length,
      'activePharmacies': _pharmacies
          .where((p) => p.status == PharmacyStatus.active)
          .length,
      'totalAuditLogs': _auditLogs.length,
      'recentLogs': _auditLogs
          .where(
            (l) => l.timestamp.isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            ),
          )
          .length,
    };
  }
}
