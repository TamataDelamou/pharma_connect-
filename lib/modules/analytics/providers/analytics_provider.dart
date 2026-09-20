import 'package:flutter/material.dart';
import '../models/daily_stats.dart';
import '../models/analytics_dashboard.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service = AnalyticsService();

  List<DailyStats> _dailyStats = [];
  List<PharmacyPerformance> _pharmacyPerformance = [];
  List<ProductPerformance> _topProducts = [];
  AnalyticsSummary? _summary;
  List<AnalyticsDashboard> _dashboards = [];
  AnalyticsDashboard? _selectedDashboard;
  bool _isLoading = false;
  String? _error;

  List<DailyStats> get dailyStats => _dailyStats;
  List<PharmacyPerformance> get pharmacyPerformance => _pharmacyPerformance;
  List<ProductPerformance> get topProducts => _topProducts;
  AnalyticsSummary? get summary => _summary;
  List<AnalyticsDashboard> get dashboards => _dashboards;
  AnalyticsDashboard? get selectedDashboard => _selectedDashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedDashboardForTest(AnalyticsDashboard? value) =>
      _selectedDashboard = value;

  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getDailyStats(),
        _service.getPharmaciesPerformance(),
        _service.getTopProducts(),
        _service.getSummary(),
      ]);
      _dailyStats = results[0] as List<DailyStats>;
      _pharmacyPerformance = results[1] as List<PharmacyPerformance>;
      _topProducts = results[2] as List<ProductPerformance>;
      _summary = results[3] as AnalyticsSummary;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDashboards(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboards = await _service.getUserDashboards(userId);
      if (_dashboards.isEmpty) {
        // Create default
        _selectedDashboard = await _service.getDefaultDashboard(userId);
        _dashboards = await _service.getUserDashboards(userId);
      } else {
        _selectedDashboard = _dashboards.firstWhere(
          (d) => d.isDefault,
          orElse: () => _dashboards.first,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveDashboard(AnalyticsDashboard dashboard) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      AnalyticsDashboard saved;
      if (dashboard.id.isEmpty || dashboard.id.startsWith('default_')) {
        saved = await _service.createDashboard(dashboard);
        _dashboards.add(saved);
      } else {
        saved = await _service.updateDashboard(dashboard);
        final index = _dashboards.indexWhere((d) => d.id == saved.id);
        if (index != -1) _dashboards[index] = saved;
      }
      _selectedDashboard = saved;
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

  Future<bool> deleteDashboard(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteDashboard(id);
      _dashboards.removeWhere((d) => d.id == id);
      if (_selectedDashboard?.id == id) {
        _selectedDashboard = _dashboards.isNotEmpty ? _dashboards.first : null;
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

  void selectDashboard(String id) {
    _selectedDashboard = _dashboards.firstWhere((d) => d.id == id);
    notifyListeners();
  }

  void clearSelected() {
    _selectedDashboard = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
