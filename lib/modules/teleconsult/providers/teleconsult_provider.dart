import 'package:flutter/material.dart';
import '../models/consultation.dart';
import '../models/consultation_status.dart';
import '../models/availability_slot.dart';
import '../services/teleconsult_service.dart';

class TeleconsultProvider extends ChangeNotifier {
  final TeleconsultService _service = TeleconsultService();

  List<Consultation> _consultations = [];
  Consultation? _selectedConsultation;
  List<AvailabilitySlot> _availabilitySlots = [];
  List<DateTime> _availableSlotsForDate = [];
  List<Map<String, dynamic>> _professionals = [];
  bool _isLoading = false;
  String? _error;

  List<Consultation> get consultations => _consultations;
  Consultation? get selectedConsultation => _selectedConsultation;
  List<AvailabilitySlot> get availabilitySlots => _availabilitySlots;
  List<DateTime> get availableSlotsForDate => _availableSlotsForDate;

  /// Audit Module 15 (CNS, 29/08/2026) : remplace la liste mockée de
  /// professionnels de `teleconsult_booking_screen.dart` — voir
  /// `TeleconsultService.getAvailableProfessionals()`.
  List<Map<String, dynamic>> get professionals => _professionals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedConsultationForTest(Consultation? value) =>
      _selectedConsultation = value;

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

  // ---- Consultations ----

  Future<void> loadConsultations({
    required String userId,
    bool asProfessional = false,
    ConsultationStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _consultations = await _service.getConsultationsForUser(
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

  Future<void> loadConsultation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedConsultation = await _service.getConsultation(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createConsultation(Consultation consultation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createConsultation(consultation);
      _consultations.insert(0, saved);
      _selectedConsultation = saved;
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

  Future<bool> updateConsultationStatus(
    String id,
    ConsultationStatus newStatus, {
    String? professionalNotes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateConsultationStatus(
        id,
        newStatus,
        professionalNotes: professionalNotes,
      );
      final index = _consultations.indexWhere((c) => c.id == id);
      if (index != -1) _consultations[index] = updated;
      if (_selectedConsultation?.id == id) _selectedConsultation = updated;
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

  Future<bool> deleteConsultation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteConsultation(id);
      _consultations.removeWhere((c) => c.id == id);
      if (_selectedConsultation?.id == id) _selectedConsultation = null;
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

  Future<bool> saveAvailabilitySlot(AvailabilitySlot slot) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      AvailabilitySlot saved;
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
    _selectedConsultation = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
