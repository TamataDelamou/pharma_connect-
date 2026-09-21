import 'package:equatable/equatable.dart';

class B2BNegotiation extends Equatable {
  final String id;
  final String offerId;
  final String buyerPharmacyId;
  final int proposedPrice;
  final int? proposedQuantity;
  final String status; // pending, accepted, rejected, countered
  final int? counterOfferPrice;
  final int? counterOfferQuantity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const B2BNegotiation({
    required this.id,
    required this.offerId,
    required this.buyerPharmacyId,
    required this.proposedPrice,
    this.proposedQuantity,
    required this.status,
    this.counterOfferPrice,
    this.counterOfferQuantity,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  B2BNegotiation copyWith({
    String? id,
    String? offerId,
    String? buyerPharmacyId,
    int? proposedPrice,
    int? proposedQuantity,
    String? status,
    int? counterOfferPrice,
    int? counterOfferQuantity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return B2BNegotiation(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      buyerPharmacyId: buyerPharmacyId ?? this.buyerPharmacyId,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      proposedQuantity: proposedQuantity ?? this.proposedQuantity,
      status: status ?? this.status,
      counterOfferPrice: counterOfferPrice ?? this.counterOfferPrice,
      counterOfferQuantity: counterOfferQuantity ?? this.counterOfferQuantity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'offer_id': offerId,
    'buyer_pharmacy_id': buyerPharmacyId,
    'proposed_price': proposedPrice,
    if (proposedQuantity != null) 'proposed_quantity': proposedQuantity,
    'status': status,
    if (counterOfferPrice != null) 'counter_offer_price': counterOfferPrice,
    if (counterOfferQuantity != null)
      'counter_offer_quantity': counterOfferQuantity,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory B2BNegotiation.fromJson(Map<String, dynamic> json) => B2BNegotiation(
    id: json['id'] as String,
    offerId: json['offer_id'] as String,
    buyerPharmacyId: json['buyer_pharmacy_id'] as String,
    proposedPrice: json['proposed_price'] as int,
    proposedQuantity: json['proposed_quantity'] as int?,
    status: json['status'] as String,
    counterOfferPrice: json['counter_offer_price'] as int?,
    counterOfferQuantity: json['counter_offer_quantity'] as int?,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    offerId,
    buyerPharmacyId,
    proposedPrice,
    proposedQuantity,
    status,
    counterOfferPrice,
    counterOfferQuantity,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Rejetée';
      case 'countered':
        return 'Contre-offre';
      default:
        return status;
    }
  }
}
