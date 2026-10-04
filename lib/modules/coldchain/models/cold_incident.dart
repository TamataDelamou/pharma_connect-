import '../../../core/theme/palette.dart';

enum IncidentSeverity { critical, major, minor }

class ColdIncident {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String batchId;
  final String batchNumber;
  final String productName;
  final DateTime occurredAt;
  final DateTime? resolvedAt;
  final double temperatureRecorded;
  final double minTemperature;
  final double maxTemperature;
  final IncidentSeverity severity;
  final String? resolutionNotes;
  final String? reportedBy;
  final bool isResolved;
  final String? affectedProducts;

  ColdIncident({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.batchId,
    required this.batchNumber,
    required this.productName,
    required this.occurredAt,
    this.resolvedAt,
    required this.temperatureRecorded,
    required this.minTemperature,
    required this.maxTemperature,
    required this.severity,
    this.resolutionNotes,
    this.reportedBy,
    this.isResolved = false,
    this.affectedProducts,
  });

  factory ColdIncident.fromJson(Map<String, dynamic> json) => ColdIncident(
    id: json['id'] as String,
    equipmentId: json['equipment_id'] as String,
    equipmentName: json['equipment_name'] as String,
    batchId: json['batch_id'] as String? ?? 'unknown',
    batchNumber: json['batch_number'] as String? ?? 'unknown',
    productName: json['product_name'] as String? ?? 'Produit inconnu',
    occurredAt: DateTime.parse(json['occurred_at'] as String),
    resolvedAt: json['resolved_at'] != null
        ? DateTime.parse(json['resolved_at'] as String)
        : null,
    temperatureRecorded: (json['temperature_recorded'] as num).toDouble(),
    minTemperature: (json['min_temperature'] as num).toDouble(),
    maxTemperature: (json['max_temperature'] as num).toDouble(),
    severity: IncidentSeverity.values.byName(json['severity'] as String),
    resolutionNotes: json['resolution_notes'] as String?,
    reportedBy: json['reported_by'] as String?,
    isResolved: json['is_resolved'] as bool? ?? false,
    affectedProducts: json['affected_products'] as String?,
  );

  // batch_id est une FK uuid vers traceable_batches : le littéral 'unknown'
  // utilisé quand aucun lot n'est identifié n'est pas un uuid valide.
  Map<String, dynamic> toJson() => {
    'id': id,
    'equipment_id': equipmentId,
    'equipment_name': equipmentName,
    'batch_id': batchId == 'unknown' ? null : batchId,
    'batch_number': batchNumber == 'unknown' ? null : batchNumber,
    'product_name': productName,
    'occurred_at': occurredAt.toIso8601String(),
    'resolved_at': resolvedAt?.toIso8601String(),
    'temperature_recorded': temperatureRecorded,
    'min_temperature': minTemperature,
    'max_temperature': maxTemperature,
    'severity': severity.name,
    'resolution_notes': resolutionNotes,
    'reported_by': reportedBy,
    'is_resolved': isResolved,
    'affected_products': affectedProducts,
  };

  ColdIncident copyWith({
    String? id,
    String? equipmentId,
    String? equipmentName,
    String? batchId,
    String? batchNumber,
    String? productName,
    DateTime? occurredAt,
    DateTime? resolvedAt,
    double? temperatureRecorded,
    double? minTemperature,
    double? maxTemperature,
    IncidentSeverity? severity,
    String? resolutionNotes,
    String? reportedBy,
    bool? isResolved,
    String? affectedProducts,
  }) {
    return ColdIncident(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      batchId: batchId ?? this.batchId,
      batchNumber: batchNumber ?? this.batchNumber,
      productName: productName ?? this.productName,
      occurredAt: occurredAt ?? this.occurredAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      temperatureRecorded: temperatureRecorded ?? this.temperatureRecorded,
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      severity: severity ?? this.severity,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      reportedBy: reportedBy ?? this.reportedBy,
      isResolved: isResolved ?? this.isResolved,
      affectedProducts: affectedProducts ?? this.affectedProducts,
    );
  }

  String get severityLabel {
    switch (severity) {
      case IncidentSeverity.critical:
        return 'Critique';
      case IncidentSeverity.major:
        return 'Majeure';
      case IncidentSeverity.minor:
        return 'Mineure';
    }
  }

  ColorRole get severityColor {
    switch (severity) {
      case IncidentSeverity.critical:
        return ColorRole.danger;
      case IncidentSeverity.major:
        return ColorRole.warning;
      case IncidentSeverity.minor:
        return ColorRole.warningStrong;
    }
  }

  String get duration {
    if (resolvedAt == null) return 'En cours';
    final diff = resolvedAt!.difference(occurredAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}min';
    return '${diff.inDays}j ${diff.inHours % 24}h';
  }
}
