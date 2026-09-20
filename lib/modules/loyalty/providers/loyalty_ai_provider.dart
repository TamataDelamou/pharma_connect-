import 'package:flutter/material.dart';
import '../models/health_challenge.dart';
import '../services/loyalty_ai_service.dart';

class LoyaltyAIProvider extends ChangeNotifier {
  final LoyaltyAIService _service = LoyaltyAIService();

  List<HealthChallenge> _challenges = [];
  List<ChallengeProgress> _progress = [];
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  List<HealthChallenge> get challenges => _challenges;
  List<ChallengeProgress> get progress => _progress;
  List<Map<String, dynamic>> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Future<void> generateChallenges(String patientId) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      _challenges = await _service.generatePersonalizedChallenges(patientId);
      // Load progress for each challenge
      _progress = [];
      for (final challenge in _challenges) {
        final prog = await _service.getProgress(patientId, challenge.id);
        if (prog != null) _progress.add(prog);
      }
      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendations(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _recommendations = await _service.getRecommendations(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProgress({
    required String patientId,
    required String challengeId,
    required int increment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateProgress(
        patientId: patientId,
        challengeId: challengeId,
        increment: increment,
      );
      final index = _progress.indexWhere((p) => p.id == updated.id);
      if (index != -1) {
        _progress[index] = updated;
      } else {
        _progress.add(updated);
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

  Future<bool> recordHealthAction({
    required String patientId,
    required String actionType,
    required double value,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.recordHealthAction(
        patientId: patientId,
        actionType: actionType,
        value: value,
      );
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

  ChallengeProgress? getProgressForChallenge(String challengeId) {
    try {
      return _progress.firstWhere((p) => p.challengeId == challengeId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
