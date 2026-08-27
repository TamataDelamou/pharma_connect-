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

  factory BatchMovement.fromJson(Map<String, dynamic> json) => BatchMovement(
    id: json['id'] as String,
    batchId: json['batch_id'] as String,
    type: BatchMovementType.values.byName(json['type'] as String),
    fromLocation: json['from_location'] as String,
    toLocation: json['to_location'] as String,
    fromLocationType: json['from_location_type'] as String,
    toLocationType: json['to_location_type'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    userId: json['user_id'] as String?,
    userName: json['user_name'] as String?,
    trackingNumber: json['tracking_number'] as String?,
    notes: json['notes'] as String?,
    temperature: json['temperature'] as int?,
    isColdChainRequired: json['is_cold_chain_required'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'batch_id': batchId,
    'type': type.name,
    'from_location': fromLocation,
    'to_location': toLocation,
    'from_location_type': fromLocationType,
    'to_location_type': toLocationType,
    'timestamp': timestamp.toIso8601String(),
    'user_id': userId,
    'user_name': userName,
    'tracking_number': trackingNumber,
    'notes': notes,
    'temperature': temperature,
    'is_cold_chain_required': isColdChainRequired,
  };

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
