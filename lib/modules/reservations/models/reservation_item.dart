class ReservationItem {
  final String productId;
  final String productName;
  final String genericName;
  final String dosage;
  final int pricePerUnit; // unité mineure
  final int quantity;
  final int? stockAtReservation;
  final bool isSubstitution;
  // C243 : identifiant de la ligne, ordonnance à présenter au retrait, ligne
  // retirée lors d'un retrait partiel.
  final String? id;
  final bool prescriptionRequired;
  final DateTime? removedAt;
  final String? removedReason;

  ReservationItem({
    required this.productId,
    required this.productName,
    required this.genericName,
    required this.dosage,
    required this.pricePerUnit,
    required this.quantity,
    this.stockAtReservation,
    this.isSubstitution = false,
    this.id,
    this.prescriptionRequired = false,
    this.removedAt,
    this.removedReason,
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
        id: json['id'] as String?,
        prescriptionRequired: json['prescription_required'] as bool? ?? false,
        removedAt: json['removed_at'] != null
            ? DateTime.parse(json['removed_at'] as String)
            : null,
        removedReason: json['removed_reason'] as String?,
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
    'prescription_required': prescriptionRequired,
    'removed_at': removedAt?.toIso8601String(),
    'removed_reason': removedReason,
  };

  int get totalPrice => pricePerUnit * quantity;
  bool get isRemoved => removedAt != null;

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
      id: id,
      prescriptionRequired: prescriptionRequired,
      removedAt: removedAt,
      removedReason: removedReason,
    );
  }
}
