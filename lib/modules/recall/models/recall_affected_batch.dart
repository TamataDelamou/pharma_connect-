import 'package:flutter/material.dart';
import 'batch_recall_status.dart';
import '../../../core/theme/palette.dart';

class RecallAffectedBatch {
  final String id;
  final String recallId;
  final String batchId;
  final String batchNumber;
  final String productName;
  final String productId;
  final int totalUnits;
  final int unitsRecalled;
  final int unitsReturned;
  final int unitsDestroyed;
  final BatchRecallStatus status;
  final String? notes;

  RecallAffectedBatch({
    required this.id,
    required this.recallId,
    required this.batchId,
    required this.batchNumber,
    required this.productName,
    required this.productId,
    required this.totalUnits,
    this.unitsRecalled = 0,
    this.unitsReturned = 0,
    this.unitsDestroyed = 0,
    required this.status,
    this.notes,
  });

  factory RecallAffectedBatch.fromJson(Map<String, dynamic> json) =>
      RecallAffectedBatch(
        id: json['id'] as String,
        recallId: json['recall_id'] as String? ?? '',
        batchId: json['batch_id'] as String? ?? '',
        batchNumber: json['batch_number'] as String,
        productName: json['product_name'] as String,
        productId: json['product_id'] as String? ?? '',
        totalUnits: json['total_units'] as int? ?? 0,
        unitsRecalled: json['units_recalled'] as int? ?? 0,
        unitsReturned: json['units_returned'] as int? ?? 0,
        unitsDestroyed: json['units_destroyed'] as int? ?? 0,
        status: BatchRecallStatus.values.byName(json['status'] as String),
        notes: json['notes'] as String?,
      );

  // batch_id/product_id sont des FK uuid nullable (traceable_batches,
  // products) : omises si la valeur fournie n'est pas un id réel connu.
  Map<String, dynamic> toJson() => {
    'id': id,
    'recall_id': recallId.isEmpty ? null : recallId,
    'batch_id': batchId.isEmpty ? null : batchId,
    'batch_number': batchNumber,
    'product_name': productName,
    'product_id': productId.isEmpty ? null : productId,
    'total_units': totalUnits,
    'units_recalled': unitsRecalled,
    'units_returned': unitsReturned,
    'units_destroyed': unitsDestroyed,
    'status': status.name,
    'notes': notes,
  };

  RecallAffectedBatch copyWith({
    String? id,
    String? recallId,
    String? batchId,
    String? batchNumber,
    String? productName,
    String? productId,
    int? totalUnits,
    int? unitsRecalled,
    int? unitsReturned,
    int? unitsDestroyed,
    BatchRecallStatus? status,
    String? notes,
  }) {
    return RecallAffectedBatch(
      id: id ?? this.id,
      recallId: recallId ?? this.recallId,
      batchId: batchId ?? this.batchId,
      batchNumber: batchNumber ?? this.batchNumber,
      productName: productName ?? this.productName,
      productId: productId ?? this.productId,
      totalUnits: totalUnits ?? this.totalUnits,
      unitsRecalled: unitsRecalled ?? this.unitsRecalled,
      unitsReturned: unitsReturned ?? this.unitsReturned,
      unitsDestroyed: unitsDestroyed ?? this.unitsDestroyed,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  double get completionRate {
    if (totalUnits == 0) return 0;
    return (unitsReturned + unitsDestroyed) / totalUnits;
  }

  String get statusLabel {
    switch (status) {
      case BatchRecallStatus.pending:
        return 'En attente';
      case BatchRecallStatus.inProgress:
        return 'En cours';
      case BatchRecallStatus.completed:
        return 'Terminé';
      case BatchRecallStatus.partial:
        return 'Partiel';
      case BatchRecallStatus.cancelled:
        return 'Annulé';
    }
  }

  ColorRole get statusColor {
    switch (status) {
      case BatchRecallStatus.pending:
        return ColorRole.textMuted;
      case BatchRecallStatus.inProgress:
        return ColorRole.warning;
      case BatchRecallStatus.completed:
        return ColorRole.success;
      case BatchRecallStatus.partial:
        return ColorRole.primary;
      case BatchRecallStatus.cancelled:
        return ColorRole.danger;
    }
  }
}
