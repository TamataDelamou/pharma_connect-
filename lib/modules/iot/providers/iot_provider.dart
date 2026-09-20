import 'package:flutter/material.dart';
import '../models/iot_device.dart';
import '../models/temperature_reading.dart';
import '../models/iot_alert.dart';
import '../services/iot_service.dart';

class IotProvider extends ChangeNotifier {
  final IotService _service = IotService();

  List<IotDevice> _devices = [];
  IotDevice? _selectedDevice;
  List<TemperatureReading> _readings = [];
  List<IotAlert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<IotDevice> get devices => _devices;
  IotDevice? get selectedDevice => _selectedDevice;
  List<TemperatureReading> get readings => _readings;
  List<IotAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedDeviceForTest(IotDevice? value) => _selectedDevice = value;

  // ---- Devices ----

  Future<void> loadDevices({String? pharmacyId, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _devices = await _service.getDevices(
        pharmacyId: pharmacyId,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDevice(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedDevice = await _service.getDevice(id);
      if (_selectedDevice != null) {
        await loadReadings(id);
        await loadAlerts(deviceId: id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveDevice(IotDevice device) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      IotDevice saved;
      if (device.id.isEmpty || device.id.startsWith('temp_')) {
        saved = await _service.createDevice(device);
        _devices.insert(0, saved);
      } else {
        saved = await _service.updateDevice(device);
        final index = _devices.indexWhere((d) => d.id == saved.id);
        if (index != -1) _devices[index] = saved;
      }
      _selectedDevice = saved;
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

  Future<bool> deleteDevice(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteDevice(id);
      _devices.removeWhere((d) => d.id == id);
      if (_selectedDevice?.id == id) _selectedDevice = null;
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

  // ---- Readings ----

  Future<void> loadReadings(String deviceId, {int limit = 50}) async {
    try {
      _readings = await _service.getTemperatureReadings(
        deviceId: deviceId,
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> simulateReading(String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.simulateReading(deviceId);
      await loadReadings(deviceId);
      await loadAlerts(deviceId: deviceId);
      if (_selectedDevice != null) {
        _selectedDevice = await _service.getDevice(deviceId);
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

  // ---- Alerts ----

  Future<void> loadAlerts({String? deviceId, String? status}) async {
    try {
      _alerts = await _service.getAlerts(deviceId: deviceId, status: status);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> updateAlertStatus(String id, String newStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateAlertStatus(id, newStatus);
      final index = _alerts.indexWhere((a) => a.id == updated.id);
      if (index != -1) _alerts[index] = updated;
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

  void clearSelected() {
    _selectedDevice = null;
    _readings = [];
    _alerts = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
