import 'dart:math';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/demand_prediction.dart';
import '../models/price_recommendation.dart';
import '../models/fraud_alert.dart';
import '../models/product_recommendation.dart';

class SalesAIService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();
  final _random = Random();

  // ---- Demand Prediction ----

  Future<List<DemandPrediction>> predictDemand({
    required String pharmacyId,
    required String productId,
    String productName,
    int days = 30,
  }) async {
    // Get historical sales
    final sales = await _getHistoricalSales(pharmacyId, productId);

    // Simple moving average
    final avgDaily = sales.isEmpty
        ? 5
        : sales.reduce((a, b) => a + b) / sales.length;

    final predictions = <DemandPrediction>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i + 1));
      final dayOfWeek = date.weekday;

      // Weekend adjustment
      var factor = (dayOfWeek == 6 || dayOfWeek == 7) ? 1.3 : 0.9;
      factor += (_random.nextDouble() - 0.5) * 0.2;

      final predicted = (avgDaily * factor).round();
      final lowerBound = (predicted * 0.8).round();
      final upperBound = (predicted * 1.2).round();

      predictions.add(
        DemandPrediction(
          id: _uuid.v4(),
          pharmacyId: pharmacyId,
          productId: productId,
          productName: productName.isNotEmpty ? productName : 'Produit',
          predictionDate: date,
          predictedQuantity: predicted,
          lowerBound: lowerBound,
          upperBound: upperBound,
          confidenceLevel: 0.85,
          modelVersion: 'v1.0',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    // Save predictions
    for (final pred in predictions) {
      await _client.from('demand_predictions').insert(pred.toJson());
    }

    return predictions;
  }

  Future<List<double>> _getHistoricalSales(
    String pharmacyId,
    String productId,
  ) async {
    try {
      final response = await _client
          .from('pos_sale_items')
          .select('quantity, created_at')
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .limit(30);

      return (response as List)
          .map((e) => (e as Map<String, dynamic>)['quantity'] as double)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ---- Price Optimization ----

  Future<PriceRecommendation> optimizePrice({
    required String pharmacyId,
    required String productId,
    required String productName,
    required int currentPrice,
  }) async {
    // Simulate price optimization
    final competitorPrices = [
      currentPrice * (0.85 + _random.nextDouble() * 0.3),
    ];

    final avgCompetitor =
        competitorPrices.reduce((a, b) => a + b) / competitorPrices.length;
    final recommendedPrice = (currentPrice * 0.95 + avgCompetitor * 0.05)
        .round();
    final minPrice = (recommendedPrice * 0.85).round();
    final maxPrice = (recommendedPrice * 1.15).round();

    final reasons = [
      'Prix compétitif par rapport au marché',
      'Marge bénéficiaire optimale',
      'Demande élastique au prix',
    ];

    final recommendation = PriceRecommendation(
      id: _uuid.v4(),
      pharmacyId: pharmacyId,
      productId: productId,
      productName: productName,
      currentPrice: currentPrice,
      recommendedPrice: recommendedPrice,
      minPrice: minPrice,
      maxPrice: maxPrice,
      reason: reasons[_random.nextInt(reasons.length)],
      confidenceLevel: 0.7 + _random.nextDouble() * 0.2,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    await _client.from('price_recommendations').insert(recommendation.toJson());
    return recommendation;
  }

  // ---- Fraud Detection ----

  Future<List<FraudAlert>> detectFraud({
    required String pharmacyId,
    required String transactionId,
    required int amount,
    String? paymentMethod,
  }) async {
    final alerts = <FraudAlert>[];

    // Check for amount anomaly
    if (amount > 1000000) {
      alerts.add(
        FraudAlert(
          id: _uuid.v4(),
          pharmacyId: pharmacyId,
          transactionId: transactionId,
          alertType: 'amount_anomaly',
          severity: 'high',
          description: 'Montant de vente élevé: ${amount} GNF',
          score: 0.85,
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    // Check for refund frequency
    final refunds = await _client
        .from('pos_sales')
        .select('id', count: CountOption.exact)
        .eq('pharmacy_id', pharmacyId)
        .eq('status', 'refunded')
        .gte(
          'created_at',
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        );

    if (refunds.length > 5) {
      alerts.add(
        FraudAlert(
          id: _uuid.v4(),
          pharmacyId: pharmacyId,
          transactionId: transactionId,
          alertType: 'frequency_anomaly',
          severity: 'medium',
          description: 'Taux de remboursement élevé: ${refunds.length} en 1h',
          score: 0.6,
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    // Save alerts
    for (final alert in alerts) {
      await _client.from('fraud_alerts').insert(alert.toJson());
    }

    return alerts;
  }

  // ---- Product Recommendations ----

  Future<List<ProductRecommendation>> getRecommendations(
    String productId,
  ) async {
    try {
      final response = await _client
          .from('product_recommendations')
          .select('*, products:recommended_product_id(name)')
          .eq('product_id', productId)
          .order('score', ascending: false)
          .limit(5);

      return (response as List)
          .map((e) => ProductRecommendation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> generateRecommendations() async {
    await _client.rpc('generate_product_recommendations');
  }

  // ---- Sentiment Analysis for Returns ----

  Future<String> analyzeSentiment(String text) async {
    if (text.isEmpty) return 'neutral';

    final positive = [
      'satisfait',
      'bon',
      'bien',
      'correct',
      'rapide',
      'efficace',
      'merci',
    ];
    final negative = [
      'mauvais',
      'déçu',
      'problème',
      'erreur',
      'défectueux',
      'endommagé',
      'délai',
      'retard',
    ];

    final lower = text.toLowerCase();
    var positiveScore = 0;
    var negativeScore = 0;

    for (final word in positive) {
      if (lower.contains(word)) positiveScore++;
    }
    for (final word in negative) {
      if (lower.contains(word)) negativeScore++;
    }

    if (positiveScore > negativeScore) return 'positive';
    if (negativeScore > positiveScore) return 'negative';
    return 'neutral';
  }
}
