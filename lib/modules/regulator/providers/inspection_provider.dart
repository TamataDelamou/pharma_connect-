import 'package:flutter/material.dart';
import '../models/regulatory_inspection.dart';
import '../services/regulator_service.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4 : provider pour la
// table `regulatory_inspections`, jusqu'ici entièrement orpheline.
class InspectionProvider extends ChangeNotifier {
  final RegulatorService _service = RegulatorService();

  List<RegulatoryInspection> _inspections = [];
  RegulatoryInspection? _selectedInspection;
  bool _isLoading = false;
  String? _error;

  List<RegulatoryInspection> get inspections => _inspections;
  RegulatoryInspection? get selectedInspection => _selectedInspection;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInspections({String? entityType, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _inspections = await _service.getInspections(
        entityType: entityType,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadInspection(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedInspection = await _service.getInspection(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveInspection(RegulatoryInspection inspection) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      RegulatoryInspection saved;
      if (inspection.id.isEmpty || inspection.id.startsWith('temp_')) {
        saved = await _service.createInspection(inspection);
        _inspections.insert(0, saved);
      } else {
        saved = await _service.updateInspection(inspection);
        final index = _inspections.indexWhere((i) => i.id == saved.id);
        if (index != -1) _inspections[index] = saved;
      }
      _selectedInspection = saved;
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

  Future<bool> deleteInspection(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteInspection(id);
      _inspections.removeWhere((i) => i.id == id);
      if (_selectedInspection?.id == id) _selectedInspection = null;
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
    _selectedInspection = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
