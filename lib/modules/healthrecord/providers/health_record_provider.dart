import 'package:flutter/material.dart';
import '../models/health_record.dart';
import '../services/health_record_service.dart';

class HealthRecordProvider extends ChangeNotifier {
  final HealthRecordService _service = HealthRecordService();

  List<HealthRecord> _records = [];
  HealthRecord? _selectedRecord;
  bool _isLoading = false;
  String? _error;

  List<HealthRecord> get records => _records;
  HealthRecord? get selectedRecord => _selectedRecord;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedRecordForTest(HealthRecord? value) => _selectedRecord = value;

  Future<void> loadRecords(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _records = await _service.getRecordsForPatient(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecord(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedRecord = await _service.getRecord(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveRecord(HealthRecord record) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      HealthRecord saved;
      if (record.id.isEmpty || record.id.startsWith('temp_')) {
        saved = await _service.createRecord(record);
        _records.insert(0, saved);
      } else {
        saved = await _service.updateRecord(record);
        final index = _records.indexWhere((r) => r.id == saved.id);
        if (index != -1) _records[index] = saved;
      }
      _selectedRecord = saved;
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

  Future<bool> deleteRecord(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteRecord(id);
      _records.removeWhere((r) => r.id == id);
      if (_selectedRecord?.id == id) _selectedRecord = null;
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
    _selectedRecord = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
