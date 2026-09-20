import 'package:equatable/equatable.dart';

class ForecastPrediction extends Equatable {
  final String id;
  final String
  metricType; // consultations, prescriptions, reservations, deliveries, revenue, stock
  final DateTime targetDate;
  final double predictedValue;
  final double? lowerBound;
  final double? upperBound;
  final double confidenceLevel;
  final String modelVersion;
  final double? actualValue;
  final String? pharmacyId;
  final String? productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const ForecastPrediction({
    required this.id,
    required this.metricType,
    required this.targetDate,
    required this.predictedValue,
    this.lowerBound,
    this.upperBound,
    this.confidenceLevel = 0.8,
    this.modelVersion = 'v1',
    this.actualValue,
    this.pharmacyId,
    this.productId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  ForecastPrediction copyWith({
    String? id,
    String? metricType,
    DateTime? targetDate,
    double? predictedValue,
    double? lowerBound,
    double? upperBound,
    double? confidenceLevel,
    String? modelVersion,
    double? actualValue,
    String? pharmacyId,
    String? productId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return ForecastPrediction(
      id: id ?? this.id,
      metricType: metricType ?? this.metricType,
      targetDate: targetDate ?? this.targetDate,
      predictedValue: predictedValue ?? this.predictedValue,
      lowerBound: lowerBound ?? this.lowerBound,
      upperBound: upperBound ?? this.upperBound,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      modelVersion: modelVersion ?? this.modelVersion,
      actualValue: actualValue ?? this.actualValue,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'metric_type': metricType,
    'target_date': targetDate.toIso8601String().split('T').first,
    'predicted_value': predictedValue,
    if (lowerBound != null) 'lower_bound': lowerBound,
    if (upperBound != null) 'upper_bound': upperBound,
    'confidence_level': confidenceLevel,
    'model_version': modelVersion,
    if (actualValue != null) 'actual_value': actualValue,
    if (pharmacyId != null) 'pharmacy_id': pharmacyId,
    if (productId != null) 'product_id': productId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory ForecastPrediction.fromJson(Map<String, dynamic> json) =>
      ForecastPrediction(
        id: json['id'] as String,
        metricType: json['metric_type'] as String,
        targetDate: DateTime.parse(json['target_date'] as String),
        predictedValue: (json['predicted_value'] as num).toDouble(),
        lowerBound: (json['lower_bound'] as num?)?.toDouble(),
        upperBound: (json['upper_bound'] as num?)?.toDouble(),
        confidenceLevel: (json['confidence_level'] as num?)?.toDouble() ?? 0.8,
        modelVersion: json['model_version'] as String? ?? 'v1',
        actualValue: (json['actual_value'] as num?)?.toDouble(),
        pharmacyId: json['pharmacy_id'] as String?,
        productId: json['product_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    metricType,
    targetDate,
    predictedValue,
    lowerBound,
    upperBound,
    confidenceLevel,
    modelVersion,
    actualValue,
    pharmacyId,
    productId,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get metricLabel {
    switch (metricType) {
      case 'consultations':
        return 'Consultations';
      case 'prescriptions':
        return 'Prescriptions';
      case 'reservations':
        return 'Réservations';
      case 'deliveries':
        return 'Livraisons';
      case 'revenue':
        return 'Chiffre d\'affaires';
      case 'stock':
        return 'Stock';
      default:
        return metricType;
    }
  }
}

class HistoricalData extends Equatable {
  final String id;
  final String metricType;
  final DateTime date;
  final double value;
  final String? pharmacyId;
  final String? productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  const HistoricalData({
    required this.id,
    required this.metricType,
    required this.date,
    required this.value,
    this.pharmacyId,
    this.productId,
    required this.createdAt,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'metric_type': metricType,
    'date': date.toIso8601String().split('T').first,
    'value': value,
    if (pharmacyId != null) 'pharmacy_id': pharmacyId,
    if (productId != null) 'product_id': productId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory HistoricalData.fromJson(Map<String, dynamic> json) => HistoricalData(
    id: json['id'] as String,
    metricType: json['metric_type'] as String,
    date: DateTime.parse(json['date'] as String),
    value: (json['value'] as num).toDouble(),
    pharmacyId: json['pharmacy_id'] as String?,
    productId: json['product_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    metricType,
    date,
    value,
    pharmacyId,
    productId,
    createdAt,
    updatedAt,
    gsgId,
    gsgOrgId,
  ];
}

class ForecastAlert extends Equatable {
  final String id;
  final String metricType;
  final String? pharmacyId;
  final String? productId;
  final String thresholdType; // min, max, change_percent
  final double thresholdValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const ForecastAlert({
    required this.id,
    required this.metricType,
    this.pharmacyId,
    this.productId,
    required this.thresholdType,
    required this.thresholdValue,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  ForecastAlert copyWith({
    String? id,
    String? metricType,
    String? pharmacyId,
    String? productId,
    String? thresholdType,
    double? thresholdValue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) => ForecastAlert(
    id: id ?? this.id,
    metricType: metricType ?? this.metricType,
    pharmacyId: pharmacyId ?? this.pharmacyId,
    productId: productId ?? this.productId,
    thresholdType: thresholdType ?? this.thresholdType,
    thresholdValue: thresholdValue ?? this.thresholdValue,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    gsgId: gsgId ?? this.gsgId,
    gsgOrgId: gsgOrgId ?? this.gsgOrgId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'metric_type': metricType,
    if (pharmacyId != null) 'pharmacy_id': pharmacyId,
    if (productId != null) 'product_id': productId,
    'threshold_type': thresholdType,
    'threshold_value': thresholdValue,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory ForecastAlert.fromJson(Map<String, dynamic> json) => ForecastAlert(
    id: json['id'] as String,
    metricType: json['metric_type'] as String,
    pharmacyId: json['pharmacy_id'] as String?,
    productId: json['product_id'] as String?,
    thresholdType: json['threshold_type'] as String,
    thresholdValue: (json['threshold_value'] as num).toDouble(),
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    metricType,
    pharmacyId,
    productId,
    thresholdType,
    thresholdValue,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get thresholdLabel {
    switch (thresholdType) {
      case 'min':
        return 'Seuil minimum';
      case 'max':
        return 'Seuil maximum';
      case 'change_percent':
        return 'Changement en %';
      default:
        return thresholdType;
    }
  }
}
