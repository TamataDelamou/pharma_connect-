import 'package:flutter/material.dart';
import '../models/intervention.dart';
import '../models/homecare_status.dart';
import '../models/homecare_availability_slot.dart';
import '../services/homecare_service.dart';

class HomecareProvider extends ChangeNotifier {
  final HomecareService _service = HomecareService();

  List<Intervention> _interventions = [];
  Intervention? _selectedIntervention;
  List<HomecareAvailabilitySlot> _availabilitySlots = [];
  List<DateTime> _availableSlotsForDate = [];
  List<Map<String, dynamic>> _professionals = [];
  bool _isLoading = false;
  String? _error;

  List<Intervention> get interventions => _interventions;
  Intervention? get selectedIntervention => _selectedIntervention;
  List<HomecareAvailabilitySlot> get availabilitySlots => _availabilitySlots;
  List<DateTime> get availableSlotsForDate => _availableSlotsForDate;
  List<Map<String, dynamic>> get professionals => _professionals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedInterventionForTest(Intervention? value) =>
      _selectedIntervention = value;

  // Audit Module 18 (HOM, 30/08/2026) : remplace `_mockProfessionals`
  // (IDs non-UUID) dans `HomecareBookingScreen` — voir
  // `HomecareService.getAvailableProfessionals()`.
  Future<void> loadProfessionals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _professionals = await _service.getAvailableProfessionals();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadInterventions({
    required String userId,
    bool asProfessional = false,
    HomecareStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _interventions = await _service.getInterventionsForUser(
        userId: userId,
        asProfessional: asProfessional,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadIntervention(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedIntervention = await _service.getIntervention(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createIntervention(Intervention intervention) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createIntervention(intervention);
      _interventions.insert(0, saved);
      _selectedIntervention = saved;
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

  Future<bool> updateInterventionStatus(
    String id,
    HomecareStatus newStatus, {
    String? report,
    String? refusalReason,
    int? patientRating,
    String? patientFeedback,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateInterventionStatus(
        id,
        newStatus,
        report: report,
        refusalReason: refusalReason,
        patientRating: patientRating,
        patientFeedback: patientFeedback,
      );
      final index = _interventions.indexWhere((i) => i.id == id);
      if (index != -1) _interventions[index] = updated;
      if (_selectedIntervention?.id == id) _selectedIntervention = updated;
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

  Future<bool> deleteIntervention(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteIntervention(id);
      _interventions.removeWhere((i) => i.id == id);
      if (_selectedIntervention?.id == id) _selectedIntervention = null;
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

  Future<void> loadAvailabilitySlots(String professionalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _availabilitySlots = await _service.getAvailabilitySlots(professionalId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveAvailabilitySlot(HomecareAvailabilitySlot slot) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      HomecareAvailabilitySlot saved;
      if (slot.id.isEmpty || slot.id.startsWith('temp_')) {
        saved = await _service.createAvailabilitySlot(slot);
        _availabilitySlots.add(saved);
      } else {
        saved = await _service.updateAvailabilitySlot(slot);
        final index = _availabilitySlots.indexWhere((s) => s.id == saved.id);
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

  Future<bool> deleteAvailabilitySlot(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteAvailabilitySlot(id);
      _availabilitySlots.removeWhere((s) => s.id == id);
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

  Future<void> loadAvailableSlotsForDate(
    String professionalId,
    DateTime date,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _availableSlotsForDate = await _service.getAvailableSlotsForDate(
        professionalId: professionalId,
        date: date,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearSelected() {
    _selectedIntervention = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
