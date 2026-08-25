import 'package:flutter/material.dart';
import '../models/prescription.dart';
import '../models/prescription_item.dart';
import '../models/prescription_status.dart';
import '../services/prescription_service.dart';
import '../services/ocr_service.dart';

enum PrescriptionUploadStatus { idle, uploading, processing, ready, error }

class PrescriptionProvider extends ChangeNotifier {
  final PrescriptionService _service = PrescriptionService();
  final OcrService _ocrService = OcrService();

  List<Prescription> _prescriptions = [];
  Prescription? _selectedPrescription;
  PrescriptionUploadStatus _uploadStatus = PrescriptionUploadStatus.idle;
  String? _uploadError;
  List<PrescriptionItem> _extractedItems = [];
  double _ocrConfidenceScore = 0.0;
  bool _isProcessingOcr = false;
  Map<String, bool> _availabilityMap = {};
  String? _error; // <-- Ajouté
  bool _isLoading = false;

  List<Prescription> get prescriptions => _prescriptions;
  Prescription? get selectedPrescription => _selectedPrescription;
  PrescriptionUploadStatus get uploadStatus => _uploadStatus;
  String? get uploadError => _uploadError;
  List<PrescriptionItem> get extractedItems => _extractedItems;
  double get ocrConfidenceScore => _ocrConfidenceScore;
  bool get isProcessingOcr => _isProcessingOcr;
  Map<String, bool> get availabilityMap => _availabilityMap;
  String? get error => _error; // <-- Ajouté
  bool get isLoading => _isLoading;

  List<Prescription> get pendingPrescriptions => _prescriptions
      .where((p) => p.status == PrescriptionStatus.pending)
      .toList();

  List<Prescription> get validatedPrescriptions => _prescriptions
      .where((p) => p.status == PrescriptionStatus.validated)
      .toList();

  List<Prescription> get dispensedPrescriptions => _prescriptions
      .where((p) => p.status == PrescriptionStatus.dispensed)
      .toList();

  // ==================== CHARGEMENT ====================

  Future<void> loadPrescriptions({PrescriptionStatus? status}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _prescriptions = await _service.getPrescriptions(status: status);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPrescription(String id) async {
    try {
      _selectedPrescription = await _service.getPrescription(id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== UPLOAD & OCR ====================

  Future<void> uploadPrescription(
    String imagePath,
    String patientId,
    String patientName,
  ) async {
    _uploadStatus = PrescriptionUploadStatus.uploading;
    _uploadError = null;
    _extractedItems = [];
    _ocrConfidenceScore = 0.0;
    _availabilityMap = {};
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      _uploadStatus = PrescriptionUploadStatus.processing;
      _isProcessingOcr = true;
      notifyListeners();

      final ocrResult = await _ocrService.extractFromImage(imagePath);
      _extractedItems = ocrResult['items'] as List<PrescriptionItem>;
      _ocrConfidenceScore = ocrResult['confidenceScore'] as double;
      _isProcessingOcr = false;

      final prescription = await _service.createPrescription(
        patientId: patientId,
        patientName: patientName,
        imageUrl: imagePath,
        items: _extractedItems,
        ocrConfidenceScore: _ocrConfidenceScore,
      );

      _selectedPrescription = prescription;
      _prescriptions.add(prescription);
      _uploadStatus = PrescriptionUploadStatus.ready;

      await _checkAvailability(_extractedItems);

      notifyListeners();
    } catch (e) {
      _uploadStatus = PrescriptionUploadStatus.error;
      _uploadError = 'Erreur lors de l\'upload: $e';
      _isProcessingOcr = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== VALIDATION ====================

  Future<void> validatePrescription(String id, {String? notes}) async {
    try {
      final updated = await _service.validatePrescription(id, notes: notes);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) _prescriptions[index] = updated;
      if (_selectedPrescription?.id == id) _selectedPrescription = updated;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> dispensePrescription(String id) async {
    try {
      final updated = await _service.dispensePrescription(id);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) _prescriptions[index] = updated;
      if (_selectedPrescription?.id == id) _selectedPrescription = updated;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> archivePrescription(String id) async {
    try {
      await _service.archivePrescription(id);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) {
        _prescriptions[index] = _prescriptions[index].copyWith(
          status: PrescriptionStatus.archived,
        );
      }
      if (_selectedPrescription?.id == id) {
        _selectedPrescription = _selectedPrescription!.copyWith(
          status: PrescriptionStatus.archived,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== CORRECTION ====================

  Future<List<String>> suggestCorrection(String wrongName) async {
    return await _ocrService.suggestCorrection(wrongName);
  }

  void updateExtractedItem(int index, PrescriptionItem newItem) {
    if (index < _extractedItems.length) {
      _extractedItems[index] = newItem;
      notifyListeners();
    }
  }

  void updateExtractedItems(List<PrescriptionItem> newItems) {
    _extractedItems = newItems;
    notifyListeners();
  }

  // ==================== AVAILABILITY ====================

  Future<void> _checkAvailability(List<PrescriptionItem> items) async {
    _availabilityMap = {};
    for (final item in items) {
      final isAvailable = DateTime.now().millisecondsSinceEpoch % 3 != 0;
      _availabilityMap[item.medicationName] = isAvailable;
    }
    notifyListeners();
  }

  // ==================== RECHERCHE ====================

  Future<void> searchPrescriptions(String query) async {
    try {
      _prescriptions = await _service.searchPrescriptions(query);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== NETTOYAGE ====================

  void clearSelected() {
    _selectedPrescription = null;
    _extractedItems = [];
    _ocrConfidenceScore = 0.0;
    _availabilityMap = {};
    _uploadStatus = PrescriptionUploadStatus.idle;
    _uploadError = null;
    notifyListeners();
  }

  void resetUpload() {
    _uploadStatus = PrescriptionUploadStatus.idle;
    _uploadError = null;
    _extractedItems = [];
    _ocrConfidenceScore = 0.0;
    _availabilityMap = {};
    _isProcessingOcr = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
