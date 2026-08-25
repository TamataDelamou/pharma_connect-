import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/alert_type.dart';
import '../models/alert_severity.dart';
import '../models/alert_status.dart';
import '../models/alert_preferences.dart';
import '../services/alert_service.dart';

class AlertProvider extends ChangeNotifier {
  final AlertService _service = AlertService();

  List<Alert> _alerts = [];
  Alert? _selectedAlert;
  AlertPreferences _preferences = const AlertPreferences();
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Alert> get alerts => _alerts;
  Alert? get selectedAlert => _selectedAlert;
  AlertPreferences get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Alert> get unreadAlerts => _alerts.where((a) => !a.isRead).toList();
  List<Alert> get criticalAlerts =>
      _alerts.where((a) => a.severity == AlertSeverity.critical).toList();
  List<Alert> get warningAlerts =>
      _alerts.where((a) => a.severity == AlertSeverity.warning).toList();

  int get unreadCount => unreadAlerts.length;
  int get criticalCount => criticalAlerts.length;

  // ==================== CHARGEMENT ====================

  Future<void> loadAlerts({
    AlertStatus? status,
    AlertType? type,
    AlertSeverity? severity,
    String? userId,
    String? pharmacyId,
    bool unreadOnly = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _service.getAlerts(
        status: status,
        type: type,
        severity: severity,
        userId: userId,
        pharmacyId: pharmacyId,
        unreadOnly: unreadOnly,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAlert(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedAlert = await _service.getAlert(id);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    try {
      _preferences = await _service.getPreferences();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== ACTIONS ====================

  Future<bool> markAsRead(String id) async {
    try {
      final updated = await _service.markAsRead(id);
      _updateAlert(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllAsRead({String? userId, String? pharmacyId}) async {
    try {
      final updated = await _service.markAllAsRead(
        userId: userId,
        pharmacyId: pharmacyId,
      );
      for (final alert in updated) {
        _updateAlert(alert);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> dismissAlert(String id) async {
    try {
      final updated = await _service.dismissAlert(id);
      _updateAlert(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsActioned(String id) async {
    try {
      final updated = await _service.markAsActioned(id);
      _updateAlert(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updatePreferences(AlertPreferences newPreferences) async {
    try {
      await _service.updatePreferences(newPreferences);
      _preferences = newPreferences;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== UTILITAIRES ====================

  void _updateAlert(Alert updated) {
    final index = _alerts.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _alerts[index] = updated;
    }
    if (_selectedAlert?.id == updated.id) {
      _selectedAlert = updated;
    }
    notifyListeners();
  }

  void clearSelected() {
    _selectedAlert = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
