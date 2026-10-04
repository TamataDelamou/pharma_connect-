/// C243 : une ligne de l'aperçu du retrait (`reservation_pickup_preview`).
class PickupLine {
  final String reservationItemId;
  final String productName;
  final String dosage;
  final int quantity;

  /// Prix indicatif noté à la réservation (unité mineure).
  final int reservedUnitPrice;

  /// Prix du jour imposé par le serveur au retrait (unité mineure).
  final int currentUnitPrice;
  final bool prescriptionRequired;

  /// Boîtes qui ne peuvent plus être remises : lot rappelé ou périmé depuis
  /// la réservation, sans autre lot vendable.
  final int unavailableQuantity;

  const PickupLine({
    required this.reservationItemId,
    required this.productName,
    required this.dosage,
    required this.quantity,
    required this.reservedUnitPrice,
    required this.currentUnitPrice,
    required this.prescriptionRequired,
    required this.unavailableQuantity,
  });

  factory PickupLine.fromJson(Map<String, dynamic> json) => PickupLine(
    reservationItemId: json['reservation_item_id'] as String,
    productName: json['product_name'] as String,
    dosage: json['dosage'] as String? ?? '',
    quantity: json['quantity'] as int? ?? 0,
    reservedUnitPrice: json['reserved_unit_price'] as int? ?? 0,
    currentUnitPrice: json['current_unit_price'] as int? ?? 0,
    prescriptionRequired: json['prescription_required'] as bool? ?? false,
    unavailableQuantity: json['unavailable_quantity'] as int? ?? 0,
  );

  bool get isUnavailable => unavailableQuantity > 0;
  int get reservedTotal => reservedUnitPrice * quantity;
  int get currentTotal => currentUnitPrice * quantity;
}
