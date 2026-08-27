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

  factory ReservationItem.fromJson(Map<String, dynamic> json) =>
      ReservationItem(
        productId: json['product_id'] as String? ?? '',
        productName: json['product_name'] as String,
        genericName: json['generic_name'] as String? ?? '',
        dosage: json['dosage'] as String? ?? '',
        pricePerUnit: json['price_per_unit'] as int? ?? 0,
        quantity: json['quantity'] as int? ?? 1,
        stockAtReservation: json['stock_at_reservation'] as int?,
        isSubstitution: json['is_substitution'] as bool? ?? false,
      );

  // id (PK de reservation_items) n'a pas d'équivalent ici : ce modèle
  // n'a pour clé naturelle que productId. Un id est généré à l'insertion
  // par ReservationService, jamais porté par ce modèle.
  Map<String, dynamic> toJson({required String reservationId}) => {
    'reservation_id': reservationId,
    'product_id': productId.isEmpty ? null : productId,
    'product_name': productName,
    'generic_name': genericName,
    'dosage': dosage,
    'price_per_unit': pricePerUnit,
    'quantity': quantity,
    'stock_at_reservation': stockAtReservation,
    'is_substitution': isSubstitution,
  };

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
