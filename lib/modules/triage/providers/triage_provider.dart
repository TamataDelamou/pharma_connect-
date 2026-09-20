import 'package:flutter/material.dart';
import '../models/triage_patient.dart';
import '../models/triage_status.dart';
import '../models/triage_assessment.dart';
import '../services/triage_service.dart';

class TriageProvider extends ChangeNotifier {
  final TriageService _service = TriageService();

  List<TriagePatient> _patients = [];
  TriagePatient? _selectedPatient;
  List<TriageAssessment> _assessments = [];
  TriageAssessment? _selectedAssessment;
  bool _isLoading = false;
  String? _error;

  List<TriagePatient> get patients => _patients;
  TriagePatient? get selectedPatient => _selectedPatient;
  List<TriageAssessment> get assessments => _assessments;
  TriageAssessment? get selectedAssessment => _selectedAssessment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedPatientForTest(TriagePatient? value) => _selectedPatient = value;

  // ---- Patients ----

  Future<void> loadPatients({
    TriageStatus? status,
    String? nurseId,
    String? patientId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _patients = await _service.getPatients(
        status: status,
        nurseId: nurseId,
        patientId: patientId,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPatient(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedPatient = await _service.getPatient(id);
      if (_selectedPatient != null) {
        await loadAssessmentsForPatient(_selectedPatient!.id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPatient(TriagePatient patient) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createPatient(patient);
      _patients.insert(0, saved);
      _selectedPatient = saved;
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

  Future<bool> updatePatient(TriagePatient patient) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.updatePatient(patient);
      final index = _patients.indexWhere((p) => p.id == saved.id);
      if (index != -1) _patients[index] = saved;
      if (_selectedPatient?.id == saved.id) _selectedPatient = saved;
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

  Future<bool> updatePatientStatus(
    String id,
    TriageStatus newStatus, {
    String? notes,
    String? assignedDepartment,
    String? assignedDoctorId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updatePatientStatus(
        id,
        newStatus,
        notes: notes,
        assignedDepartment: assignedDepartment,
        assignedDoctorId: assignedDoctorId,
      );
      final index = _patients.indexWhere((p) => p.id == id);
      if (index != -1) _patients[index] = updated;
      if (_selectedPatient?.id == id) _selectedPatient = updated;
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

  Future<bool> deletePatient(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deletePatient(id);
      _patients.removeWhere((p) => p.id == id);
      if (_selectedPatient?.id == id) _selectedPatient = null;
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

  // ---- Assessments ----

  Future<void> loadAssessmentsForPatient(String triagePatientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _assessments = await _service.getAssessmentsForPatient(triagePatientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createAssessment(TriageAssessment assessment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createAssessment(assessment);
      _assessments.insert(0, saved);
      _selectedAssessment = saved;
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

  Future<bool> updateAssessment(TriageAssessment assessment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.updateAssessment(assessment);
      final index = _assessments.indexWhere((a) => a.id == saved.id);
      if (index != -1) _assessments[index] = saved;
      if (_selectedAssessment?.id == saved.id) _selectedAssessment = saved;
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

  Future<bool> deleteAssessment(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteAssessment(id);
      _assessments.removeWhere((a) => a.id == id);
      if (_selectedAssessment?.id == id) _selectedAssessment = null;
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
    _selectedPatient = null;
    _selectedAssessment = null;
    _assessments = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
