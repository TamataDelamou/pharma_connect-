import 'package:equatable/equatable.dart';

class DemandForecast extends Equatable {
  final String id;
  final String? productId;
  final String? pharmacyId;
  final String productName;
  final DateTime forecastDate;
  final int predictedDemand;
  final int? lowerBound;
  final int? upperBound;
  final double confidenceLevel;
  final String modelVersion;
  final int? actualDemand;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const DemandForecast({
    required this.id,
    this.productId,
    this.pharmacyId,
    required this.productName,
    required this.forecastDate,
    required this.predictedDemand,
    this.lowerBound,
    this.upperBound,
    this.confidenceLevel = 0.8,
    this.modelVersion = 'v1',
    this.actualDemand,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  DemandForecast copyWith({
    String? id,
    String? productId,
    String? pharmacyId,
    String? productName,
    DateTime? forecastDate,
    int? predictedDemand,
    int? lowerBound,
    int? upperBound,
    double? confidenceLevel,
    String? modelVersion,
    int? actualDemand,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return DemandForecast(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      productName: productName ?? this.productName,
      forecastDate: forecastDate ?? this.forecastDate,
      predictedDemand: predictedDemand ?? this.predictedDemand,
      lowerBound: lowerBound ?? this.lowerBound,
      upperBound: upperBound ?? this.upperBound,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      modelVersion: modelVersion ?? this.modelVersion,
      actualDemand: actualDemand ?? this.actualDemand,
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
        if (productId != null) 'product_id': productId,
        if (pharmacyId != null) 'pharmacy_id': pharmacyId,
        'product_name': productName,
        'forecast_date': forecastDate.toIso8601String().split('T').first,
        'predicted_demand': predictedDemand,
        if (lowerBound != null) 'lower_bound': lowerBound,
        if (upperBound != null) 'upper_bound': upperBound,
        'confidence_level': confidenceLevel,
        'model_version': modelVersion,
        if (actualDemand != null) 'actual_demand': actualDemand,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (createdBy != null) 'created_by': createdBy,
        if (updatedBy != null) 'updated_by': updatedBy,
        if (gsgId != null) 'gsg_id': gsgId,
        if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
      };

  factory DemandForecast.fromJson(Map<String, dynamic> json) => DemandForecast(
        id: json['id'] as String,
        productId: json['product_id'] as String?,
        pharmacyId: json['pharmacy_id'] as String?,
        productName: json['product_name'] as String,
        forecastDate: DateTime.parse(json['forecast_date'] as String),
        predictedDemand: json['predicted_demand'] as int,
        lowerBound: json['lower_bound'] as int?,
        upperBound: json['upper_bound'] as int?,
        confidenceLevel: (json['confidence_level'] as num?)?.toDouble() ?? 0.8,
        modelVersion: json['model_version'] as String? ?? 'v1',
        actualDemand: json['actual_demand'] as int?,
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
        productId,
        pharmacyId,
        productName,
        forecastDate,
        predictedDemand,
        lowerBound,
        upperBound,
        confidenceLevel,
        modelVersion,
        actualDemand,
        createdAt,
        updatedAt,
        createdBy,
        updatedBy,
        gsgId,
        gsgOrgId,
      ];
}

class ReorderAlert extends Equatable {
  final String id;
  final String? pharmacyId;
  final String? productId;
  final String productName;
  final int currentStock;
  final int reorderPoint;
  final int? quantityToOrder;
  final String status; // pending, ordered, cancelled, completed
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const ReorderAlert({
    required this.id,
    this.pharmacyId,
    this.productId,
    required this.productName,
    required this.currentStock,
    required this.reorderPoint,
    this.quantityToOrder,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  // Audit Module 11 (29/08/2026) : la classe ne comportait qu'un constructeur
  // placeholder invalide (`const ReorderAlert({...});`, non compilable) et
  // aucune méthode `copyWith`/`toJson`/`fromJson` — pourtant déjà appelées
  // par `ForecastService` (`_saveReorderAlert`, `checkReorderAlerts`), qui
  // n'aurait donc jamais pu compiler. Complétée sur le même patron que
  // `DemandForecast` ci-dessus.
  ReorderAlert copyWith({
    String? id,
    String? pharmacyId,
    String? productId,
    String? productName,
    int? currentStock,
    int? reorderPoint,
    int? quantityToOrder,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return ReorderAlert(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      currentStock: currentStock ?? this.currentStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      quantityToOrder: quantityToOrder ?? this.quantityToOrder,
      status: status ?? this.status,
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
        if (pharmacyId != null) 'pharmacy_id': pharmacyId,
        if (productId != null) 'product_id': productId,
        'product_name': productName,
        'current_stock': currentStock,
        'reorder_point': reorderPoint,
        if (quantityToOrder != null) 'quantity_to_order': quantityToOrder,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (createdBy != null) 'created_by': createdBy,
        if (updatedBy != null) 'updated_by': updatedBy,
        if (gsgId != null) 'gsg_id': gsgId,
        if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
      };

  factory ReorderAlert.fromJson(Map<String, dynamic> json) => ReorderAlert(
        id: json['id'] as String,
        pharmacyId: json['pharmacy_id'] as String?,
        productId: json['product_id'] as String?,
        productName: json['product_name'] as String,
        currentStock: json['current_stock'] as int,
        reorderPoint: json['reorder_point'] as int,
        quantityToOrder: json['quantity_to_order'] as int?,
        status: json['status'] as String? ?? 'pending',
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
        pharmacyId,
        productId,
        productName,
        currentStock,
        reorderPoint,
        quantityToOrder,
        status,
        createdAt,
        updatedAt,
        createdBy,
        updatedBy,
        gsgId,
        gsgOrgId,
      ];

  String get statusLabel {
    switch (status) {
      case 'pending':
        return '⏳ En attente';
      case 'ordered':
        return '📦 Commandé';
      case 'cancelled':
        return '❌ Annulé';
      case 'completed':
        return '✅ Terminé';
      default:
        return status;
    }
  }

  bool get isUrgent => currentStock <= reorderPoint * 0.5;
}
