import 'package:pharma_connect/core/utils/user_message.dart';
import 'package:flutter/material.dart';
import '../models/health_goal.dart';
import '../models/health_milestone.dart';
import '../services/health_goal_service.dart';

class HealthGoalProvider extends ChangeNotifier {
  final HealthGoalService _service = HealthGoalService();

  List<HealthGoal> _goals = [];
  HealthGoal? _selectedGoal;
  List<HealthMilestone> _milestones = [];
  bool _isLoading = false;
  String? _error;

  List<HealthGoal> get goals => _goals;
  HealthGoal? get selectedGoal => _selectedGoal;
  List<HealthMilestone> get milestones => _milestones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGoals(String patientId, {String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _goals = await _service.getGoals(patientId, status: status);
    } catch (e) {
      _error = userMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadGoal(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedGoal = await _service.getGoal(id);
    } catch (e) {
      _error = userMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveGoal(HealthGoal goal) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      HealthGoal saved;
      if (goal.id.isEmpty || goal.id.startsWith('temp_')) {
        saved = await _service.createGoal(goal);
        _goals.insert(0, saved);
      } else {
        saved = await _service.updateGoal(goal);
        final index = _goals.indexWhere((g) => g.id == saved.id);
        if (index != -1) _goals[index] = saved;
      }
      _selectedGoal = saved;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProgress(String id, double increment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateGoalProgress(id, increment);
      await loadGoal(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGoal(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      if (_selectedGoal?.id == id) _selectedGoal = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMilestones(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _milestones = await _service.getMilestones(patientId);
    } catch (e) {
      _error = userMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearSelected() {
    _selectedGoal = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
