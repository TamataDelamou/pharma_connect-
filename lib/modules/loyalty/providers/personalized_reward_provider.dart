import 'package:flutter/material.dart';
import '../models/personalized_reward.dart';
import '../services/personalized_reward_service.dart';

class PersonalizedRewardProvider extends ChangeNotifier {
  final PersonalizedRewardService _service = PersonalizedRewardService();

  List<PersonalizedReward> _activeRewards = [];
  List<PersonalizedReward> _allRewards = [];
  PersonalizedReward? _selectedReward;
  // Audit Module 16 (FID, 29/08/2026) : mémorisé explicitement plutôt que
  // déduit de `_activeRewards.isNotEmpty ? _activeRewards.first.patientId :
  // ''` dans `useReward()` — ce repli silencieux vers une chaîne vide
  // aurait envoyé un `patientId` invalide à la prochaine requête dès que la
  // récompense utilisée était la seule de la liste active.
  String? _patientId;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  List<PersonalizedReward> get activeRewards => _activeRewards;
  List<PersonalizedReward> get allRewards => _allRewards;
  PersonalizedReward? get selectedReward => _selectedReward;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Future<void> loadActiveRewards(String patientId) async {
    _patientId = patientId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _activeRewards = await _service.getActiveRewards(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllRewards(String patientId) async {
    _patientId = patientId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allRewards = await _service.getAllRewards(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadReward(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedReward = await _service.getReward(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> generateRewards(String patientId) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      await _service.generateRewards(patientId);
      await loadActiveRewards(patientId);
      await loadAllRewards(patientId);
      _isGenerating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> useReward(String rewardId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.useReward(rewardId);
      // Refresh lists
      final patientId = _patientId;
      if (patientId != null) {
        await loadActiveRewards(patientId);
        await loadAllRewards(patientId);
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

  void clearSelected() {
    _selectedReward = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
