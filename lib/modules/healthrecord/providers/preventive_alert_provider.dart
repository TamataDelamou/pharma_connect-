import 'package:flutter/material.dart';
import '../models/preventive_alert.dart';
import '../models/preventive_alert_history.dart';
import '../services/preventive_alert_service.dart';

class PreventiveAlertProvider extends ChangeNotifier {
  final PreventiveAlertService _service = PreventiveAlertService();

  List<PreventiveAlert> _alerts = [];
  List<PreventiveAlertHistory> _history = [];
  PreventiveAlert? _selectedAlert;
  bool _isLoading = false;
  String? _error;

  List<PreventiveAlert> get alerts => _alerts;
  List<PreventiveAlertHistory> get history => _history;
  PreventiveAlert? get selectedAlert => _selectedAlert;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAlerts(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _alerts = await _service.getPatientAlerts(patientId);
      _history = await _service.getAlertHistory(patientId);
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

  Future<bool> saveAlert(PreventiveAlert alert) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      PreventiveAlert saved;
      if (alert.id.isEmpty || alert.id.startsWith('temp_')) {
        saved = await _service.createAlert(alert);
        _alerts.insert(0, saved);
      } else {
        saved = await _service.updateAlert(alert);
        final index = _alerts.indexWhere((a) => a.id == saved.id);
        if (index != -1) _alerts[index] = saved;
      }
      _selectedAlert = saved;
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
      _alerts.removeWhere((a) => a.id == id);
      if (_selectedAlert?.id == id) _selectedAlert = null;
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

  Future<bool> toggleAlert(String id, bool isActive) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.toggleAlert(id, isActive);
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isActive: isActive);
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

  Future<void> checkAlerts(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.checkAndTriggerAlerts(patientId);
      await loadAlerts(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
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
