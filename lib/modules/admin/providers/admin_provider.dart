import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../models/admin_role.dart';
import '../models/admin_permission.dart';
import '../models/admin_pharmacy.dart';
import '../models/pharmacy_status.dart';
import '../models/audit_log.dart';
import '../models/system_config.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  List<AdminUser> _users = [];
  AdminUser? _selectedUser;
  List<AdminPharmacy> _pharmacies = [];
  AdminPharmacy? _selectedPharmacy;
  List<AuditLog> _auditLogs = [];
  List<SystemConfig> _configs = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AdminUser> get users => _users;
  AdminUser? get selectedUser => _selectedUser;
  List<AdminPharmacy> get pharmacies => _pharmacies;

  /// Pose une liste d'officines sans appel au serveur (tests et captures
  /// d'écran).
  @visibleForTesting
  set pharmaciesForTesting(List<AdminPharmacy> value) {
    _pharmacies = value;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
  AdminPharmacy? get selectedPharmacy => _selectedPharmacy;
  List<AuditLog> get auditLogs => _auditLogs;
  List<SystemConfig> get configs => _configs;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<AdminUser> get activeUsers => _users.where((u) => u.isActive).toList();

  List<AdminUser> get pendingUsers =>
      _users.where((u) => !u.isVerified).toList();

  List<AdminPharmacy> get pendingPharmacies =>
      _pharmacies.where((p) => p.isPending).toList();

  List<AdminPharmacy> get activePharmacies =>
      _pharmacies.where((p) => p.isActive).toList();

  // ==================== CHARGEMENT ====================

  Future<void> loadUsers({
    AdminRole? role,
    bool? isActive,
    bool? isVerified,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _service.getUsers(
        role: role,
        isActive: isActive,
        isVerified: isVerified,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUser(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedUser = await _service.getUser(id);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPharmacies({
    PharmacyStatus? status,
    String? groupId,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pharmacies = await _service.getPharmacies(
        status: status,
        groupId: groupId,
        isActive: isActive,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPharmacy(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedPharmacy = await _service.getPharmacy(id);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAuditLogs({
    String? userId,
    String? resource,
    String? resourceId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _auditLogs = await _service.getAuditLogs(
        userId: userId,
        resource: resource,
        resourceId: resourceId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadConfigs({String? category}) async {
    try {
      _configs = await _service.getConfigs(category: category);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadStatistics() async {
    try {
      _statistics = await _service.getStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== ACTIONS UTILISATEURS ====================

  Future<AdminUser?> createUser({
    required String userId,
    required String email,
    required String fullName,
    required AdminRole role,
    List<AdminPermission>? permissions,
    String? phone,
    String? createdBy,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _service.createUser(
        userId: userId,
        email: email,
        fullName: fullName,
        role: role,
        permissions: permissions,
        phone: phone,
        createdBy: createdBy,
        notes: notes,
      );
      _users.add(user);
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> toggleUserActive(String id, bool isActive) async {
    try {
      final updated = await _service.toggleUserActive(id, isActive);
      _updateUser(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyUser(String id) async {
    try {
      final updated = await _service.verifyUser(id);
      _updateUser(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== ACTIONS PHARMACIES ====================

  Future<AdminPharmacy?> createPharmacy({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pharmacy = await _service.createPharmacy(
        name: name,
        address: address,
        phone: phone,
        email: email,
        licenseNumber: licenseNumber,
        managerId: managerId,
        managerName: managerName,
        latitude: latitude,
        longitude: longitude,
        groupId: groupId,
        groupName: groupName,
        notes: notes,
      );
      _pharmacies.add(pharmacy);
      _isLoading = false;
      notifyListeners();
      return pharmacy;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePharmacyStatus(String id, PharmacyStatus status) async {
    try {
      final updated = await _service.updatePharmacyStatus(id, status);
      _updatePharmacy(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPharmacy(String id) async {
    try {
      final updated = await _service.verifyPharmacy(id);
      _updatePharmacy(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> approvePharmacy(String id) async {
    try {
      final updated = await _service.approvePharmacy(id);
      _updatePharmacy(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// C252 : pose, corrige ou retire (deux valeurs nulles) la position d'une
  /// officine.
  Future<bool> updatePharmacyPosition(
    String id, {
    required double? latitude,
    required double? longitude,
  }) async {
    try {
      final updated = await _service.updatePharmacyPosition(
        id,
        latitude: latitude,
        longitude: longitude,
      );
      _updatePharmacy(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== ACTIONS CONFIGURATION ====================

  Future<bool> updateConfig(String key, String value, String updatedBy) async {
    try {
      final updated = await _service.updateConfig(key, value, updatedBy);
      final index = _configs.indexWhere((c) => c.key == key);
      if (index != -1) {
        _configs[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== UTILITAIRES ====================

  void _updateUser(AdminUser updated) {
    final index = _users.indexWhere((u) => u.id == updated.id);
    if (index != -1) {
      _users[index] = updated;
    }
    if (_selectedUser?.id == updated.id) {
      _selectedUser = updated;
    }
    notifyListeners();
  }

  void _updatePharmacy(AdminPharmacy updated) {
    final index = _pharmacies.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _pharmacies[index] = updated;
    }
    if (_selectedPharmacy?.id == updated.id) {
      _selectedPharmacy = updated;
    }
    notifyListeners();
  }

  void clearSelected() {
    _selectedUser = null;
    _selectedPharmacy = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
