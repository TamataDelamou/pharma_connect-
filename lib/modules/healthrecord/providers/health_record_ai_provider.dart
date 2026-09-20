import 'package:flutter/material.dart';
import '../models/health_record.dart';
import '../models/health_record_summary.dart';
import '../services/health_record_ai_service.dart';

class HealthRecordAIProvider extends ChangeNotifier {
  final HealthRecordAIService _service = HealthRecordAIService();

  HealthRecordSummary? _summary;
  bool _isGenerating = false;
  bool _isLoading = false;
  String? _error;

  HealthRecordSummary? get summary => _summary;
  bool get isGenerating => _isGenerating;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> generateSummary(HealthRecord record) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      final analysis = await _service.generateSummary(record);
      _summary = await _service.saveSummary(record.id, analysis);
      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> loadLatestSummary(String healthRecordId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _summary = await _service.getLatestSummary(healthRecordId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
