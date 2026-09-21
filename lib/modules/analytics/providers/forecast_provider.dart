import 'package:flutter/material.dart';
import '../models/forecast.dart';
import '../services/forecast_ai_service.dart';

class ForecastProvider extends ChangeNotifier {
  final ForecastAIService _service = ForecastAIService();

  List<ForecastPrediction> _predictions = [];
  List<ForecastAlert> _alerts = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  List<ForecastPrediction> get predictions => _predictions;
  List<ForecastAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Future<void> generateForecast({
    required String metricType,
    int days = 7,
    String? pharmacyId,
    String? productId,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      _predictions = await _service.generateForecast(
        metricType: metricType,
        days: days,
        pharmacyId: pharmacyId,
        productId: productId,
      );
      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> loadForecasts({
    String? metricType,
    String? pharmacyId,
    String? productId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _predictions = await _service.getForecasts(
        metricType: metricType,
        pharmacyId: pharmacyId,
        productId: productId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAlerts({bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _alerts = await _service.getAlerts(isActive: isActive);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createAlert(ForecastAlert alert) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createAlert(alert);
      _alerts.add(saved);
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

  Future<bool> deleteAlert(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteAlert(id);
      _alerts.removeWhere((a) => a.id == id);
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
