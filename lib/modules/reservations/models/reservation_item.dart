class ReservationItem {
  final String productId;
  final String productName;
  final String genericName;
  final String dosage;
  final int pricePerUnit; // unité mineure
  final int quantity;
  final int? stockAtReservation;
  final bool isSubstitution;

  ReservationItem({
    required this.productId,
    required this.productName,
    required this.genericName,
    required this.dosage,
    required this.pricePerUnit,
    required this.quantity,
    this.stockAtReservation,
    this.isSubstitution = false,
  });

  int get totalPrice => pricePerUnit * quantity;

  ReservationItem copyWith({
    String? productId,
    String? productName,
    String? genericName,
    String? dosage,
    int? pricePerUnit,
    int? quantity,
    int? stockAtReservation,
    bool? isSubstitution,
  }) {
    return ReservationItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      genericName: genericName ?? this.genericName,
      dosage: dosage ?? this.dosage,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      quantity: quantity ?? this.quantity,
      stockAtReservation: stockAtReservation ?? this.stockAtReservation,
      isSubstitution: isSubstitution ?? this.isSubstitution,
    );
  }
}
