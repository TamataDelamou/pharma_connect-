import 'dart:math';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/forecast.dart';

class ForecastAIService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();
  final _random = Random();

  // ---- Simple Moving Average Forecast ----

  Future<List<ForecastPrediction>> generateForecast({
    required String metricType,
    int days = 7,
    String? pharmacyId,
    String? productId,
  }) async {
    // Get historical data
    final historical = await _getHistoricalData(
      metricType: metricType,
      pharmacyId: pharmacyId,
      productId: productId,
      limit: 30,
    );

    if (historical.isEmpty) {
      // Fallback: generate based on existing stats
      return _generateFallbackForecast(metricType, days, pharmacyId, productId);
    }

    // Calculate moving average
    final values = historical.map((h) => h.value).toList();
    final predictions = <ForecastPrediction>[];

    final now = DateTime.now();
    final lastDate = historical.first.date;

    // Simple moving average with trend
    final avg = values.reduce((a, b) => a + b) / values.length;
    final trend = _calculateTrend(values);

    for (int i = 0; i < days; i++) {
      final targetDate = lastDate.add(Duration(days: i + 1));
      var predicted = avg + (trend * (i + 1));

      // Add random noise for realistic variation
      predicted += (predicted * 0.05 * (_random.nextDouble() - 0.5));

      // Ensure non-negative
      predicted = max(0, predicted);

      // Calculate confidence bounds
      final stdDev = _calculateStdDev(values);
      final lowerBound = max(0, predicted - (stdDev * 1.96));
      final upperBound = predicted + (stdDev * 1.96);

      final prediction = ForecastPrediction(
        id: _uuid.v4(),
        metricType: metricType,
        targetDate: targetDate,
        predictedValue: predicted,
        lowerBound: lowerBound,
        upperBound: upperBound,
        confidenceLevel: 0.8,
        modelVersion: 'moving_avg_v1',
        pharmacyId: pharmacyId,
        productId: productId,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      predictions.add(prediction);
      await _savePrediction(prediction);
    }

    return predictions;
  }

  Future<List<HistoricalData>> _getHistoricalData({
    required String metricType,
    String? pharmacyId,
    String? productId,
    int limit = 30,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('forecast_historical_data')
          .select()
          .eq('metric_type', metricType);

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (productId != null) {
        query = query.eq('product_id', productId);
      }

      final response = await query
          .order('date', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => HistoricalData.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<ForecastPrediction> _savePrediction(
    ForecastPrediction prediction,
  ) async {
    try {
      final data = prediction.toJson();
      final response = await _client
          .from('forecast_predictions')
          .insert(data)
          .select()
          .single();
      return ForecastPrediction.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return prediction; // Return unsaved prediction
    }
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0;
    final n = values.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i.toDouble();
      sumY += values[i];
      sumXY += i.toDouble() * values[i];
      sumX2 += i.toDouble() * i.toDouble();
    }
    return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  }

  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;
    final avg = values.reduce((a, b) => a + b) / values.length;
    final squaredDiff = values
        .map((v) => pow(v - avg, 2))
        .reduce((a, b) => a + b);
    return sqrt(squaredDiff / values.length);
  }

  // ---- Fallback Forecast (no historical data) ----

  List<ForecastPrediction> _generateFallbackForecast(
    String metricType,
    int days,
    String? pharmacyId,
    String? productId,
  ) {
    final predictions = <ForecastPrediction>[];
    final baseValue = _getBaseValue(metricType);
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final targetDate = now.add(Duration(days: i + 1));
      final factor = 1 + (sin(i / 7 * 2 * pi) * 0.3); // Weekly pattern
      final predicted = baseValue * factor * (0.9 + _random.nextDouble() * 0.2);

      predictions.add(
        ForecastPrediction(
          id: _uuid.v4(),
          metricType: metricType,
          targetDate: targetDate,
          predictedValue: predicted,
          confidenceLevel: 0.7,
          modelVersion: 'fallback_v1',
          pharmacyId: pharmacyId,
          productId: productId,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    return predictions;
  }

  double _getBaseValue(String metricType) {
    switch (metricType) {
      case 'consultations':
        return 45.0;
      case 'prescriptions':
        return 30.0;
      case 'reservations':
        return 25.0;
      case 'deliveries':
        return 20.0;
      case 'revenue':
        return 5000.0;
      case 'stock':
        return 120.0;
      default:
        return 50.0;
    }
  }

  // ---- Get Forecasts ----

  Future<List<ForecastPrediction>> getForecasts({
    String? metricType,
    String? pharmacyId,
    String? productId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('forecast_predictions').select();

      if (metricType != null) {
        query = query.eq('metric_type', metricType);
      }
      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (productId != null) {
        query = query.eq('product_id', productId);
      }
      if (fromDate != null) {
        query = query.gte(
          'target_date',
          fromDate.toIso8601String().split('T').first,
        );
      }
      if (toDate != null) {
        query = query.lte(
          'target_date',
          toDate.toIso8601String().split('T').first,
        );
      }

      final response = await query.order('target_date', ascending: true);
      return (response as List)
          .map((e) => ForecastPrediction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ---- Alert Checks ----

  Future<List<ForecastAlert>> getAlerts({bool? isActive}) async {
    try {
      var query = _client.from('forecast_alerts').select();

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query;
      return (response as List)
          .map((e) => ForecastAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<ForecastAlert> createAlert(ForecastAlert alert) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final data = alert
        .copyWith(
          id: id,
          createdAt: now,
          updatedAt: now,
          createdBy: SupabaseService().currentUser?.id,
          updatedBy: SupabaseService().currentUser?.id,
        )
        .toJson();
    final response = await _client
        .from('forecast_alerts')
        .insert(data)
        .select()
        .single();
    return ForecastAlert.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAlert(String id) async {
    await _client.from('forecast_alerts').delete().eq('id', id);
  }

  // ---- Accuracy Tracking ----

  Future<void> updateActualValue(String forecastId, double actualValue) async {
    await _client
        .from('forecast_predictions')
        .update({'actual_value': actualValue})
        .eq('id', forecastId);
  }
}
