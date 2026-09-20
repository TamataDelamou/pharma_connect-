import 'package:flutter/material.dart';
import '../models/loyalty_badge.dart';
import '../models/patient_badge.dart';
import '../services/badge_service.dart';

class BadgeProvider extends ChangeNotifier {
  final BadgeService _service = BadgeService();

  List<LoyaltyBadge> _allBadges = [];
  List<PatientBadge> _earnedBadges = [];
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = false;
  String? _error;

  List<LoyaltyBadge> get allBadges => _allBadges;
  List<PatientBadge> get earnedBadges => _earnedBadges;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBadges() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allBadges = await _service.getAllBadges();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPatientBadges(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _earnedBadges = await _service.getPatientBadges(patientId);
      // Check and award new badges
      await _service.checkAndAwardBadges(patientId);
      // Reload to get newly earned badges
      _earnedBadges = await _service.getPatientBadges(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLeaderboard({
    required String pharmacyId,
    String period = 'all_time',
    int limit = 10,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _leaderboard = await _service.getLeaderboard(
        pharmacyId: pharmacyId,
        period: period,
        limit: limit,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  bool hasBadge(String badgeId) {
    return _earnedBadges.any((b) => b.badgeId == badgeId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
