import 'package:flutter/material.dart';
import '../models/insurance_company.dart';
import '../models/insurance_enrollment.dart';
import '../models/reimbursement_tracking.dart';
import '../services/insurance_service.dart';

class InsuranceProvider extends ChangeNotifier {
  final InsuranceService _service = InsuranceService();

  List<InsuranceCompany> _companies = [];
  List<InsuranceEnrollment> _enrollments = [];
  InsuranceEnrollment? _selectedEnrollment;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _coverageCalculation;

  // ASR-4 (audit Module 24, Étape 2/3, 30/08/2026) : état dédié au suivi de
  // remboursement, distinct de _isLoading/_error ci-dessus pour ne pas
  // interférer avec l'état de chargement des adhésions consultées en
  // parallèle (ex. EnrollmentDetailScreen et ReimbursementStatusScreen
  // pourraient un jour partager le même provider via un même parcours).
  ReimbursementTracking? _reimbursementTracking;
  bool _isLoadingReimbursement = false;
  String? _reimbursementError;

  List<InsuranceCompany> get companies => _companies;
  List<InsuranceEnrollment> get enrollments => _enrollments;
  InsuranceEnrollment? get selectedEnrollment => _selectedEnrollment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get coverageCalculation => _coverageCalculation;
  ReimbursementTracking? get reimbursementTracking => _reimbursementTracking;
  bool get isLoadingReimbursement => _isLoadingReimbursement;
  String? get reimbursementError => _reimbursementError;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedEnrollmentForTest(InsuranceEnrollment? value) =>
      _selectedEnrollment = value;

  // ---- Companies ----

  Future<void> loadCompanies({bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _companies = await _service.getCompanies(isActive: isActive);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---- Enrollments ----

  Future<void> loadEnrollments(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _enrollments = await _service.getEnrollmentsForPatient(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadEnrollment(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedEnrollment = await _service.getEnrollment(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveEnrollment(InsuranceEnrollment enrollment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      InsuranceEnrollment saved;
      if (enrollment.id.isEmpty || enrollment.id.startsWith('temp_')) {
        saved = await _service.createEnrollment(enrollment);
        _enrollments.insert(0, saved);
      } else {
        saved = await _service.updateEnrollment(enrollment);
        final index = _enrollments.indexWhere((e) => e.id == saved.id);
        if (index != -1) _enrollments[index] = saved;
      }
      _selectedEnrollment = saved;
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

  Future<bool> deleteEnrollment(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteEnrollment(id);
      _enrollments.removeWhere((e) => e.id == id);
      if (_selectedEnrollment?.id == id) _selectedEnrollment = null;
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

  // ---- Coverage ----

  Future<Map<String, dynamic>?> calculateCoverage({
    required String enrollmentId,
    required int amount,
    String? procedureType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _coverageCalculation = await _service.calculateCoverage(
        enrollmentId: enrollmentId,
        amount: amount,
        procedureType: procedureType,
      );
      _isLoading = false;
      notifyListeners();
      return _coverageCalculation;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ---- Reimbursement Tracking ----

  // ASR-4 (audit Module 24, Étape 2/3, 30/08/2026) : remplace le mock codé en
  // dur de ReimbursementStatusScreen par un chargement réel via
  // InsuranceService.getReimbursementForClaim().
  Future<void> loadReimbursementForClaim(String claimId) async {
    _isLoadingReimbursement = true;
    _reimbursementError = null;
    notifyListeners();
    try {
      _reimbursementTracking = await _service.getReimbursementForClaim(claimId);
    } catch (e) {
      _reimbursementError = e.toString();
    }
    _isLoadingReimbursement = false;
    notifyListeners();
  }

  void clearSelected() {
    _selectedEnrollment = null;
    _coverageCalculation = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
