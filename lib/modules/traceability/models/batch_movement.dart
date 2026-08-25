class BatchMovement {
  final String id;
  final String batchId;
  final BatchMovementType type;
  final String fromLocation;
  final String toLocation;
  final String fromLocationType; // manufacturer, distributor, pharmacy, patient
  final String toLocationType;
  final DateTime timestamp;
  final String? userId;
  final String? userName;
  final String? trackingNumber;
  final String? notes;
  final int? temperature;
  final bool isColdChainRequired;

  BatchMovement({
    required this.id,
    required this.batchId,
    required this.type,
    required this.fromLocation,
    required this.toLocation,
    required this.fromLocationType,
    required this.toLocationType,
    required this.timestamp,
    this.userId,
    this.userName,
    this.trackingNumber,
    this.notes,
    this.temperature,
    this.isColdChainRequired = false,
  });

  String get typeLabel {
    switch (type) {
      case BatchMovementType.shipment:
        return 'Expédition';
      case BatchMovementType.receipt:
        return 'Réception';
      case BatchMovementType.sale:
        return 'Vente';
      case BatchMovementType.dispensation:
        return 'Dispensation';
      case BatchMovementType.customerReturn:
        return 'Retour';
      case BatchMovementType.recall:
        return 'Rappel';
      case BatchMovementType.transfer:
        return 'Transfert';
      case BatchMovementType.destruction:
        return 'Destruction';
    }
  }
}

enum BatchMovementType {
  shipment,
  receipt,
  sale,
  dispensation,
  customerReturn,
  recall,
  transfer,
  destruction,
}
