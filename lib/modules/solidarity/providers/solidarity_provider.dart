import 'package:flutter/material.dart';
import '../models/solidarity_program.dart';
import '../models/solidarity_beneficiary.dart';
import '../services/solidarity_service.dart';

class SolidarityProvider extends ChangeNotifier {
  final SolidarityService _service = SolidarityService();

  List<SolidarityProgram> _programs = [];
  SolidarityProgram? _selectedProgram;
  List<SolidarityBeneficiary> _beneficiaries = [];
  SolidarityBeneficiary? _selectedBeneficiary;
  bool _isLoading = false;
  String? _error;

  List<SolidarityProgram> get programs => _programs;
  SolidarityProgram? get selectedProgram => _selectedProgram;
  List<SolidarityBeneficiary> get beneficiaries => _beneficiaries;
  SolidarityBeneficiary? get selectedBeneficiary => _selectedBeneficiary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedProgramForTest(SolidarityProgram? value) =>
      _selectedProgram = value;

  // ---- Programs ----

  Future<void> loadPrograms({
    String? type,
    bool? isActive,
    String? pharmacyId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _programs = await _service.getPrograms(
        type: type,
        isActive: isActive,
        pharmacyId: pharmacyId,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProgram(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedProgram = await _service.getProgram(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveProgram(SolidarityProgram program) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      SolidarityProgram saved;
      if (program.id.isEmpty || program.id.startsWith('temp_')) {
        saved = await _service.createProgram(program);
        _programs.insert(0, saved);
      } else {
        saved = await _service.updateProgram(program);
        final index = _programs.indexWhere((p) => p.id == saved.id);
        if (index != -1) _programs[index] = saved;
      }
      _selectedProgram = saved;
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

  Future<bool> deleteProgram(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteProgram(id);
      _programs.removeWhere((p) => p.id == id);
      if (_selectedProgram?.id == id) _selectedProgram = null;
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

  // ---- Beneficiaries ----

  Future<void> loadBeneficiaries({
    String? patientId,
    String? programId,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _beneficiaries = await _service.getBeneficiaries(
        patientId: patientId,
        programId: programId,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBeneficiary(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedBeneficiary = await _service.getBeneficiary(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveBeneficiary(SolidarityBeneficiary beneficiary) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      SolidarityBeneficiary saved;
      if (beneficiary.id.isEmpty || beneficiary.id.startsWith('temp_')) {
        saved = await _service.createBeneficiary(beneficiary);
        _beneficiaries.insert(0, saved);
      } else {
        saved = await _service.updateBeneficiary(beneficiary);
        final index = _beneficiaries.indexWhere((b) => b.id == saved.id);
        if (index != -1) _beneficiaries[index] = saved;
      }
      _selectedBeneficiary = saved;
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

  Future<bool> deleteBeneficiary(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteBeneficiary(id);
      _beneficiaries.removeWhere((b) => b.id == id);
      if (_selectedBeneficiary?.id == id) _selectedBeneficiary = null;
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
    _selectedProgram = null;
    _selectedBeneficiary = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
