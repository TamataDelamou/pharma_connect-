enum AdjustmentReason {
  inventoryCorrection,
  damage,
  theft,
  returnToSupplier,
  sample,
  other,
}

extension AdjustmentReasonExtension on AdjustmentReason {
  String get label {
    switch (this) {
      case AdjustmentReason.inventoryCorrection:
        return 'Correction d\'inventaire';
      case AdjustmentReason.damage:
        return 'Produit endommagé';
      case AdjustmentReason.theft:
        return 'Vol';
      case AdjustmentReason.returnToSupplier:
        return 'Retour fournisseur';
      case AdjustmentReason.sample:
        return 'Échantillon';
      case AdjustmentReason.other:
        return 'Autre';
    }
  }
}

class StockAdjustment {
  final String id;
  final String stockItemId;
  final String? batchId;
  final AdjustmentReason reason;
  final int quantity; // Positif pour ajout, négatif pour retrait
  final String? userId;
  final String? userName;
  final String? notes;
  final DateTime timestamp;

  StockAdjustment({
    required this.id,
    required this.stockItemId,
    this.batchId,
    required this.reason,
    required this.quantity,
    this.userId,
    this.userName,
    this.notes,
    required this.timestamp,
  });
}
