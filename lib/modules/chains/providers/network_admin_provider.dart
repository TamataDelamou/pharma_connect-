import 'package:flutter/material.dart';
import '../models/network_admin_role.dart';
import '../models/network_dashboard.dart';
import '../models/network_alert.dart';
import '../services/network_admin_service.dart';

class NetworkAdminProvider extends ChangeNotifier {
  final NetworkAdminService _service = NetworkAdminService();

  List<NetworkAdminRole> _roles = [];
  NetworkAdminRole? _selectedRole;
  List<NetworkDashboard> _dashboards = [];
  NetworkDashboard? _selectedDashboard;
  List<NetworkAlert> _alerts = [];
  int _unreadAlertCount = 0;
  List<Map<String, dynamic>> _activityLog = [];
  bool _isLoading = false;
  String? _error;

  List<NetworkAdminRole> get roles => _roles;
  NetworkAdminRole? get selectedRole => _selectedRole;
  List<NetworkDashboard> get dashboards => _dashboards;
  NetworkDashboard? get selectedDashboard => _selectedDashboard;
  List<NetworkAlert> get alerts => _alerts;
  int get unreadAlertCount => _unreadAlertCount;
  List<Map<String, dynamic>> get activityLog => _activityLog;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---- Roles ----

  Future<void> loadRoles({String? userId, String? groupId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _roles = await _service.getRoles(userId: userId, groupId: groupId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRole(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedRole = await _service.getRole(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveRole(NetworkAdminRole role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      NetworkAdminRole saved;
      if (role.id.isEmpty || role.id.startsWith('temp_')) {
        saved = await _service.createRole(role);
        _roles.insert(0, saved);
      } else {
        saved = await _service.updateRole(role);
        final index = _roles.indexWhere((r) => r.id == saved.id);
        if (index != -1) _roles[index] = saved;
      }
      _selectedRole = saved;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRole(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteRole(id);
      _roles.removeWhere((r) => r.id == id);
      if (_selectedRole?.id == id) _selectedRole = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---- Dashboard ----

  Future<void> loadDashboard(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedDashboard = await _service.getDashboard(groupId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllDashboards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboards = await _service.getAllDashboards();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---- Alerts ----

  Future<void> loadAlerts({
    String? groupId,
    String? severity,
    bool? unreadOnly,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _alerts = await _service.getAlerts(
        groupId: groupId,
        severity: severity,
        unreadOnly: unreadOnly,
      );
      _unreadAlertCount = _alerts.where((a) => !a.isRead).length;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createAlert(NetworkAlert alert) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createAlert(alert);
      _alerts.insert(0, saved);
      if (!saved.isRead) _unreadAlertCount++;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAlertRead(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.markAlertRead(id);
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        if (!_alerts[index].isRead) _unreadAlertCount--;
        _alerts[index] = _alerts[index].copyWith(isRead: true);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAlert(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteAlert(id);
      final alert = _alerts.firstWhere(
        (a) => a.id == id,
        orElse: () => throw Exception('Not found'),
      );
      _alerts.removeWhere((a) => a.id == id);
      if (!alert.isRead) _unreadAlertCount--;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---- Activity Log ----

  Future<void> loadActivityLog({
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _activityLog = await _service.getActivityLog(
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearSelected() {
    _selectedRole = null;
    _selectedDashboard = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
