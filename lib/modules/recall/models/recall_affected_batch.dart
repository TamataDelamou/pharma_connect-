import 'package:flutter/material.dart';
import 'batch_recall_status.dart';

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

  Color get statusColor {
    switch (status) {
      case BatchRecallStatus.pending:
        return Colors.grey;
      case BatchRecallStatus.inProgress:
        return Colors.orange;
      case BatchRecallStatus.completed:
        return Colors.green;
      case BatchRecallStatus.partial:
        return Colors.blue;
      case BatchRecallStatus.cancelled:
        return Colors.red;
    }
  }
}
