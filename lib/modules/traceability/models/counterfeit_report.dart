// Module 12 (TRC), RG-TRC-02 — signalement d'un produit suspect (patient ou
// pharmacien). Miroir de la table public.counterfeit_reports (migration
// 20260829023000_traceability_module_fixes.sql).
class CounterfeitReport {
  final String id;
  final String reporterId;
  final String? batchId;
  final String? serialNumber;
  final String? pharmacyId;
  final String description;
  final bool aspectSuspect;
  final bool packagingSuspect;
  final bool unexpectedEffect;
  final CounterfeitReportStatus status;
  final String? alertId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CounterfeitReport({
    required this.id,
    required this.reporterId,
    this.batchId,
    this.serialNumber,
    this.pharmacyId,
    required this.description,
    this.aspectSuspect = false,
    this.packagingSuspect = false,
    this.unexpectedEffect = false,
    this.status = CounterfeitReportStatus.open,
    this.alertId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CounterfeitReport.fromJson(Map<String, dynamic> json) =>
      CounterfeitReport(
        id: json['id'] as String,
        reporterId: json['reporter_id'] as String,
        batchId: json['batch_id'] as String?,
        serialNumber: json['serial_number'] as String?,
        pharmacyId: json['pharmacy_id'] as String?,
        description: json['description'] as String,
        aspectSuspect: json['aspect_suspect'] as bool? ?? false,
        packagingSuspect: json['packaging_suspect'] as bool? ?? false,
        unexpectedEffect: json['unexpected_effect'] as bool? ?? false,
        status: CounterfeitReportStatus.values.byName(
          json['status'] as String? ?? 'open',
        ),
        alertId: json['alert_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reporter_id': reporterId,
    'batch_id': batchId,
    'serial_number': serialNumber,
    'pharmacy_id': pharmacyId,
    'description': description,
    'aspect_suspect': aspectSuspect,
    'packaging_suspect': packagingSuspect,
    'unexpected_effect': unexpectedEffect,
    'status': status.name,
    'alert_id': alertId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  String get statusLabel {
    switch (status) {
      case CounterfeitReportStatus.open:
        return 'Envoyé';
      case CounterfeitReportStatus.investigating:
        return 'En cours d\'investigation';
      case CounterfeitReportStatus.confirmed:
        return 'Contrefaçon confirmée';
      case CounterfeitReportStatus.dismissed:
        return 'Classé sans suite';
    }
  }
}

enum CounterfeitReportStatus { open, investigating, confirmed, dismissed }
