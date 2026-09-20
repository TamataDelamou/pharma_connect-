import 'package:flutter/material.dart';
import '../models/hospital.dart';
import '../models/hospital_type.dart';
import '../services/hospitals_service.dart';

class HospitalsProvider extends ChangeNotifier {
  final HospitalsService _service = HospitalsService();

  List<Hospital> _hospitals = [];
  Hospital? _selectedHospital;
  List<HospitalType> _hospitalTypes = [];
  bool _isLoading = false;
  String? _error;

  List<Hospital> get hospitals => _hospitals;
  Hospital? get selectedHospital => _selectedHospital;
  List<HospitalType> get hospitalTypes => _hospitalTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedHospitalForTest(Hospital? value) => _selectedHospital = value;

  // ---- Hospitals ----

  Future<void> loadHospitals({
    String? typeId,
    String? city,
    bool? isActive,
    bool? hasEmergency,
    String? searchQuery,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _hospitals = await _service.getHospitals(
        typeId: typeId,
        city: city,
        isActive: isActive,
        hasEmergency: hasEmergency,
        searchQuery: searchQuery,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHospital(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedHospital = await _service.getHospital(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveHospital(Hospital hospital) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      Hospital saved;
      if (hospital.id.isEmpty || hospital.id.startsWith('temp_')) {
        saved = await _service.createHospital(hospital);
        _hospitals.insert(0, saved);
      } else {
        saved = await _service.updateHospital(hospital);
        final index = _hospitals.indexWhere((h) => h.id == saved.id);
        if (index != -1) _hospitals[index] = saved;
      }
      _selectedHospital = saved;
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

  Future<bool> deleteHospital(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteHospital(id);
      _hospitals.removeWhere((h) => h.id == id);
      if (_selectedHospital?.id == id) _selectedHospital = null;
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

  // ---- Hospital Types ----

  Future<void> loadHospitalTypes({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _hospitalTypes = await _service.getHospitalTypes(category: category);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearSelected() {
    _selectedHospital = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
