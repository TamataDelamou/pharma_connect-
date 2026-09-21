import 'package:flutter/material.dart';
import '../models/family_challenge.dart';
import '../models/family_challenge_contribution.dart';
import '../models/family_activity.dart';
import '../services/family_challenge_service.dart';

class FamilyChallengeProvider extends ChangeNotifier {
  final FamilyChallengeService _service = FamilyChallengeService();

  List<FamilyChallenge> _challenges = [];
  FamilyChallenge? _selectedChallenge;
  List<FamilyChallengeContribution> _contributions = [];
  List<FamilyActivity> _activities = [];
  bool _isLoading = false;
  String? _error;

  List<FamilyChallenge> get challenges => _challenges;
  FamilyChallenge? get selectedChallenge => _selectedChallenge;
  List<FamilyChallengeContribution> get contributions => _contributions;
  List<FamilyActivity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---- Challenges ----

  Future<void> loadChallenges(String familyLinkId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _challenges = await _service.getFamilyChallenges(familyLinkId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadChallenge(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedChallenge = await _service.getFamilyChallenge(id);
      if (_selectedChallenge != null) {
        _contributions = await _service.getContributions(id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createChallenge(FamilyChallenge challenge) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createFamilyChallenge(challenge);
      _challenges.insert(0, saved);
      _selectedChallenge = saved;
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

  Future<bool> updateProgress(String id, int increment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateChallengeProgress(id, increment);
      final index = _challenges.indexWhere((c) => c.id == id);
      if (index != -1) _challenges[index] = updated;
      if (_selectedChallenge?.id == id) _selectedChallenge = updated;
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

  Future<bool> deleteChallenge(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteFamilyChallenge(id);
      _challenges.removeWhere((c) => c.id == id);
      if (_selectedChallenge?.id == id) _selectedChallenge = null;
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

  // ---- Contributions ----

  Future<bool> addContribution({
    required String challengeId,
    required String patientId,
    required int value,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final contribution = await _service.addContribution(
        challengeId: challengeId,
        patientId: patientId,
        value: value,
      );
      _contributions.add(contribution);
      // Update challenge progress
      await updateProgress(challengeId, value);
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

  // ---- Activities ----

  Future<void> loadActivities(String familyLinkId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _activities = await _service.getFamilyActivities(familyLinkId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createActivity(FamilyActivity activity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createFamilyActivity(activity);
      _activities.insert(0, saved);
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

  Future<bool> deleteActivity(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteFamilyActivity(id);
      _activities.removeWhere((a) => a.id == id);
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
    _selectedChallenge = null;
    _contributions = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
