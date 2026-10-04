import '../../../core/theme/palette.dart';

enum StockMovementType {
  purchase, // Achat fournisseur
  sale, // Vente client
  adjustment, // Ajustement manuel
  expiry, // Péremption
  breakage, // Casse
  supplierReturn, // Retour fournisseur
  transfer, // Transfert entre pharmacies
  reservation, // Réservation temporaire
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

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
    id: json['id'] as String,
    stockItemId: json['stock_item_id'] as String,
    batchId: json['batch_id'] as String?,
    type: StockMovementType.values.byName(json['type'] as String),
    quantity: json['quantity'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    userId: json['user_id'] as String?,
    userName: json['user_name'] as String?,
    referenceId: json['reference_id'] as String?,
    reason: json['reason'] as String?,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'stock_item_id': stockItemId,
    'batch_id': batchId,
    'type': type.name,
    'quantity': quantity,
    'timestamp': timestamp.toIso8601String(),
    'user_id': userId,
    'user_name': userName,
    'reference_id': referenceId,
    'reason': reason,
    'notes': notes,
  };

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

  ColorRole get typeColor {
    switch (type) {
      case StockMovementType.purchase:
      case StockMovementType.transfer:
        return ColorRole.success;
      case StockMovementType.sale:
      case StockMovementType.reservation:
        return ColorRole.primary;
      case StockMovementType.adjustment:
        return ColorRole.warning;
      case StockMovementType.expiry:
      case StockMovementType.breakage:
        return ColorRole.danger;
      case StockMovementType.supplierReturn:
        return ColorRole.secondary;
      case StockMovementType.unreservation:
        return ColorRole.primary;
    }
  }
}
