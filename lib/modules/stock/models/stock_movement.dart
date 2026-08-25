import 'package:flutter/material.dart';

enum StockMovementType {
  purchase,      // Achat fournisseur
  sale,          // Vente client
  adjustment,    // Ajustement manuel
  expiry,        // Péremption
  breakage,      // Casse
  supplierReturn, // Retour fournisseur
  transfer,      // Transfert entre pharmacies
  reservation,   // Réservation temporaire
  unreservation, // Annulation de réservation
}

class StockMovement {
  final String id;
  final String stockItemId;
  final String? batchId;
  final StockMovementType type;
  final int quantity; // Positif pour entrée, négatif pour sortie
  final DateTime timestamp;
  final String? userId;
  final String? userName;
  final String? referenceId; // prescriptionId, orderId, etc.
  final String? reason;
  final String? notes;

  StockMovement({
    required this.id,
    required this.stockItemId,
    this.batchId,
    required this.type,
    required this.quantity,
    required this.timestamp,
    this.userId,
    this.userName,
    this.referenceId,
    this.reason,
    this.notes,
  });

  String get typeLabel {
    switch (type) {
      case StockMovementType.purchase:
        return 'Achat';
      case StockMovementType.sale:
        return 'Vente';
      case StockMovementType.adjustment:
        return 'Ajustement';
      case StockMovementType.expiry:
        return 'Péremption';
      case StockMovementType.breakage:
        return 'Casse';
      case StockMovementType.supplierReturn:
        return 'Retour fournisseur';
      case StockMovementType.transfer:
        return 'Transfert';
      case StockMovementType.reservation:
        return 'Réservation';
      case StockMovementType.unreservation:
        return 'Annulation réservation';
    }
  }

  Color get typeColor {
    switch (type) {
      case StockMovementType.purchase:
      case StockMovementType.transfer:
        return Colors.green;
      case StockMovementType.sale:
      case StockMovementType.reservation:
        return Colors.blue;
      case StockMovementType.adjustment:
        return Colors.orange;
      case StockMovementType.expiry:
      case StockMovementType.breakage:
        return Colors.red;
      case StockMovementType.supplierReturn:
        return Colors.purple;
      case StockMovementType.unreservation:
        return Colors.cyan;
    }
  }
}
