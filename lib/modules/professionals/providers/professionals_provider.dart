import 'package:flutter/material.dart';
import '../models/professional_profile.dart';
import '../models/professional_availability.dart';
import '../models/professional_specialty.dart';
import '../models/professional_qualification.dart';
import '../services/professionals_service.dart';

class ProfessionalsProvider extends ChangeNotifier {
  final ProfessionalsService _service = ProfessionalsService();

  List<ProfessionalProfile> _professionals = [];
  ProfessionalProfile? _selectedProfessional;
  List<ProfessionalAvailability> _availabilitySlots = [];
  List<ProfessionalSpecialty> _specialties = [];
  List<ProfessionalQualification> _qualifications = [];
  bool _isLoading = false;
  String? _error;

  List<ProfessionalProfile> get professionals => _professionals;
  ProfessionalProfile? get selectedProfessional => _selectedProfessional;
  List<ProfessionalAvailability> get availabilitySlots => _availabilitySlots;
  List<ProfessionalSpecialty> get specialties => _specialties;
  List<ProfessionalQualification> get qualifications => _qualifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedProfessionalForTest(ProfessionalProfile? value) =>
      _selectedProfessional = value;

  // ---- Professionals ----

  Future<void> loadProfessionals({
    String? specialty,
    bool? isVerified,
    bool? acceptingNewPatients,
    String? searchQuery,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _professionals = await _service.getProfessionals(
        specialty: specialty,
        isVerified: isVerified,
        acceptingNewPatients: acceptingNewPatients,
        searchQuery: searchQuery,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProfessional(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedProfessional = await _service.getProfessional(id);
      if (_selectedProfessional != null) {
        await loadAvailability(_selectedProfessional!.id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveProfessional(ProfessionalProfile profile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      ProfessionalProfile saved;
      if (profile.id.isEmpty || profile.id.startsWith('temp_')) {
        saved = await _service.createProfile(profile);
        _professionals.insert(0, saved);
      } else {
        saved = await _service.updateProfile(profile);
        final index = _professionals.indexWhere((p) => p.id == saved.id);
        if (index != -1) _professionals[index] = saved;
      }
      _selectedProfessional = saved;
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

  Future<bool> deleteProfessional(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteProfile(id);
      _professionals.removeWhere((p) => p.id == id);
      if (_selectedProfessional?.id == id) _selectedProfessional = null;
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

  // ---- Availability ----

  Future<void> loadAvailability(String professionalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _availabilitySlots = await _service.getAvailability(professionalId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveAvailability(ProfessionalAvailability availability) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      ProfessionalAvailability saved;
      if (availability.id.isEmpty || availability.id.startsWith('temp_')) {
        saved = await _service.createAvailability(availability);
        _availabilitySlots.add(saved);
      } else {
        saved = await _service.updateAvailability(availability);
        final index = _availabilitySlots.indexWhere((a) => a.id == saved.id);
        if (index != -1) _availabilitySlots[index] = saved;
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

  Future<bool> deleteAvailability(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteAvailability(id);
      _availabilitySlots.removeWhere((a) => a.id == id);
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

  // ---- Specialties ----

  Future<void> loadSpecialties({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _specialties = await _service.getSpecialties(category: category);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---- Qualifications ----

  Future<void> loadQualifications({String? issuingBody}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _qualifications = await _service.getQualifications(
        issuingBody: issuingBody,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearSelected() {
    _selectedProfessional = null;
    _availabilitySlots = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
