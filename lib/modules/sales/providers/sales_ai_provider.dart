import 'package:flutter/material.dart';
import '../models/demand_prediction.dart';
import '../models/price_recommendation.dart';
import '../models/fraud_alert.dart';
import '../models/product_recommendation.dart';
import '../services/sales_ai_service.dart';

class SalesAIProvider extends ChangeNotifier {
  final SalesAIService _service = SalesAIService();

  List<DemandPrediction> _predictions = [];
  List<PriceRecommendation> _priceRecommendations = [];
  List<FraudAlert> _fraudAlerts = [];
  List<ProductRecommendation> _productRecommendations = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  // Getters...

  Future<void> generatePredictions({
    required String pharmacyId,
    required String productId,
    String productName = '',
    int days = 30,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      _predictions = await _service.predictDemand(
        pharmacyId: pharmacyId,
        productId: productId,
        productName: productName,
        days: days,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isGenerating = false;
    notifyListeners();
  }

  Future<void> optimizePrice({
    required String pharmacyId,
    required String productId,
    required String productName,
    required int currentPrice,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final recommendation = await _service.optimizePrice(
        pharmacyId: pharmacyId,
        productId: productId,
        productName: productName,
        currentPrice: currentPrice,
      );
      _priceRecommendations.insert(0, recommendation);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkFraud({
    required String pharmacyId,
    required String transactionId,
    required int amount,
    String? paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final alerts = await _service.detectFraud(
        pharmacyId: pharmacyId,
        transactionId: transactionId,
        amount: amount,
        paymentMethod: paymentMethod,
      );
      _fraudAlerts.insertAll(0, alerts);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecommendations(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _productRecommendations = await _service.getRecommendations(productId);
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
