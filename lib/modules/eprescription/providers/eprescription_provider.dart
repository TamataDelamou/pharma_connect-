import 'package:flutter/material.dart';
import '../models/eprescription.dart';
import '../models/eprescription_item.dart';
import '../models/eprescription_history.dart';
import '../services/eprescription_service.dart';

class EPrescriptionProvider extends ChangeNotifier {
  final EPrescriptionService _service = EPrescriptionService();

  List<EPrescription> _prescriptions = [];
  EPrescription? _selectedPrescription;
  List<EPrescriptionItem> _items = [];
  List<EPrescriptionHistory> _history = [];
  bool _isLoading = false;
  String? _error;

  List<EPrescription> get prescriptions => _prescriptions;
  EPrescription? get selectedPrescription => _selectedPrescription;
  List<EPrescriptionItem> get items => _items;
  List<EPrescriptionHistory> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedPrescriptionForTest(EPrescription? value) =>
      _selectedPrescription = value;

  Future<void> loadPrescriptions({
    String? patientId,
    String? doctorId,
    String? pharmacyId,
    String? status,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _prescriptions = await _service.getPrescriptions(
        patientId: patientId,
        doctorId: doctorId,
        pharmacyId: pharmacyId,
        status: status,
        isActive: isActive,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPrescription(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedPrescription = await _service.getPrescription(id);
      if (_selectedPrescription != null) {
        await loadItems(_selectedPrescription!.id);
        await loadHistory(_selectedPrescription!.id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> savePrescription(EPrescription prescription) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      EPrescription saved;
      if (prescription.id.isEmpty || prescription.id.startsWith('temp_')) {
        saved = await _service.createPrescription(prescription);
        _prescriptions.insert(0, saved);
      } else {
        saved = await _service.updatePrescription(prescription);
        final index = _prescriptions.indexWhere((p) => p.id == saved.id);
        if (index != -1) _prescriptions[index] = saved;
      }
      _selectedPrescription = saved;
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

  Future<bool> updateStatus(
    String id,
    String newStatus, {
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updatePrescriptionStatus(
        id,
        newStatus,
        notes: notes,
      );
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) _prescriptions[index] = updated;
      if (_selectedPrescription?.id == id) _selectedPrescription = updated;
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

  Future<bool> deletePrescription(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deletePrescription(id);
      _prescriptions.removeWhere((p) => p.id == id);
      if (_selectedPrescription?.id == id) _selectedPrescription = null;
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

  Future<void> loadItems(String prescriptionId) async {
    try {
      _items = await _service.getItems(prescriptionId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> addItem(EPrescriptionItem item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.addItem(item);
      _items.add(saved);
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

  Future<bool> updateItem(EPrescriptionItem item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.updateItem(item);
      final index = _items.indexWhere((i) => i.id == saved.id);
      if (index != -1) _items[index] = saved;
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

  Future<bool> deleteItem(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteItem(id);
      _items.removeWhere((i) => i.id == id);
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

  Future<void> loadHistory(String prescriptionId) async {
    try {
      _history = await _service.getHistory(prescriptionId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  void clearSelected() {
    _selectedPrescription = null;
    _items = [];
    _history = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
