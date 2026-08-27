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

  factory ColdChainRecord.fromJson(Map<String, dynamic> json) =>
      ColdChainRecord(
        id: json['id'] as String,
        batchId: json['batch_id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        temperature: (json['temperature'] as num).toDouble(),
        minTemperature: (json['min_temperature'] as num).toDouble(),
        maxTemperature: (json['max_temperature'] as num).toDouble(),
        location: json['location'] as String?,
        deviceId: json['device_id'] as String?,
        isBreach: json['is_breach'] as bool? ?? false,
        breachReason: json['breach_reason'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'batch_id': batchId,
    'timestamp': timestamp.toIso8601String(),
    'temperature': temperature,
    'min_temperature': minTemperature,
    'max_temperature': maxTemperature,
    'location': location,
    'device_id': deviceId,
    'is_breach': isBreach,
    'breach_reason': breachReason,
  };

  bool get isWithinRange =>
      temperature >= minTemperature && temperature <= maxTemperature;

  String get status {
    if (isBreach) return 'Rupture';
    if (isWithinRange) return 'Conforme';
    return 'Hors plage';
  }
}
