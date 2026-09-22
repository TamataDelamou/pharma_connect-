import 'package:flutter/material.dart';
import '../models/triage_ai_analysis.dart';
import '../models/triage_rules.dart';
import '../services/triage_ai_service.dart';

class TriageAIProvider extends ChangeNotifier {
  final TriageAIService _service = TriageAIService();

  TriageAIAnalysis? _currentAnalysis;
  List<TriageRule> _rules = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _error;

  TriageAIAnalysis? get currentAnalysis => _currentAnalysis;
  List<TriageRule> get rules => _rules;
  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;

  Future<TriageAIAnalysis> analyzeSymptoms({
    required String triagePatientId,
    required String symptoms,
  }) async {
    _isAnalyzing = true;
    _error = null;
    notifyListeners();
    try {
      _currentAnalysis = await _service.analyzeSymptoms(
        triagePatientId: triagePatientId,
        symptoms: symptoms,
      );
      _isAnalyzing = false;
      notifyListeners();
      return _currentAnalysis!;
    } catch (e) {
      _error = e.toString();
      _isAnalyzing = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadRules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _rules = await _service.getRules();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createRule(TriageRule rule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createRule(rule);
      _rules.add(saved);
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

  Future<bool> updateRule(TriageRule rule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.updateRule(rule);
      final index = _rules.indexWhere((r) => r.id == saved.id);
      if (index != -1) _rules[index] = saved;
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

  Future<bool> deleteRule(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteRule(id);
      _rules.removeWhere((r) => r.id == id);
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

  Future<void> submitFeedback({
    required String analysisId,
    required int actualPriority,
    required String actualDepartment,
    String? feedback,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentAnalysis = await _service.submitFeedback(
        analysisId: analysisId,
        actualPriority: actualPriority,
        actualDepartment: actualDepartment,
        feedback: feedback,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearAnalysis() {
    _currentAnalysis = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
