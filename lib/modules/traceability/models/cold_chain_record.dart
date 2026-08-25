class ColdChainRecord {
  final String id;
  final String batchId;
  final DateTime timestamp;
  final double temperature;
  final double minTemperature;
  final double maxTemperature;
  final String? location;
  final String? deviceId;
  final bool isBreach;
  final String? breachReason;

  const ColdChainRecord({
    required this.id,
    required this.batchId,
    required this.timestamp,
    required this.temperature,
    required this.minTemperature,
    required this.maxTemperature,
    this.location,
    this.deviceId,
    this.isBreach = false,
    this.breachReason,
  });

  bool get isWithinRange =>
      temperature >= minTemperature && temperature <= maxTemperature;

  String get status {
    if (isBreach) return 'Rupture';
    if (isWithinRange) return 'Conforme';
    return 'Hors plage';
  }
}
