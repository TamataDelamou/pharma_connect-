import 'dart:math';

class ForecastService {
  static final Random _random = Random();

  Future<Map<String, dynamic>> getForecast(String productId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Simuler une prévision sur 7 jours
    final currentStock = 50 + _random.nextInt(100);
    final dailyConsumption = 5 + _random.nextInt(15);

    final daysUntilOut = dailyConsumption > 0
        ? (currentStock / dailyConsumption).floor()
        : 30;

    final forecast = <String, dynamic>{
      'productId': productId,
      'currentStock': currentStock,
      'dailyConsumption': dailyConsumption,
      'daysUntilOut': daysUntilOut,
      'recommendedOrder': dailyConsumption * 7,
      'seasonalFactor': _random.nextDouble() * 1.5,
      'trend': [
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ].map((_) => _random.nextInt(20) + 10).toList(),
      'confidence': 0.7 + _random.nextDouble() * 0.25,
    };

    return forecast;
  }

  Future<List<Map<String, dynamic>>> getMultipleForecasts(
    List<String> productIds,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final forecasts = <Map<String, dynamic>>[];
    for (final id in productIds) {
      forecasts.add(await getForecast(id));
    }
    return forecasts;
  }
}
