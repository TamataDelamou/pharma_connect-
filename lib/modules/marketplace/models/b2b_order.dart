import 'package:equatable/equatable.dart';

class B2BOrder extends Equatable {
  final String id;
  final String buyerPharmacyId;
  final String sellerPharmacyId;
  final String
  status; // draft, submitted, confirmed, shipped, delivered, cancelled
  final int totalAmount;
  final String? notes;
  final DateTime? submittedAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? buyerName;
  final String? sellerName;
  final List<B2BOrderItem>? items;

  const B2BOrder({
    required this.id,
    required this.buyerPharmacyId,
    required this.sellerPharmacyId,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.submittedAt,
    this.confirmedAt,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.buyerName,
    this.sellerName,
    this.items,
  });

  B2BOrder copyWith({
    String? id,
    String? buyerPharmacyId,
    String? sellerPharmacyId,
    String? status,
    int? totalAmount,
    String? notes,
    DateTime? submittedAt,
    DateTime? confirmedAt,
    DateTime? deliveredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? buyerName,
    String? sellerName,
    List<B2BOrderItem>? items,
  }) {
    return B2BOrder(
      id: id ?? this.id,
      buyerPharmacyId: buyerPharmacyId ?? this.buyerPharmacyId,
      sellerPharmacyId: sellerPharmacyId ?? this.sellerPharmacyId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      submittedAt: submittedAt ?? this.submittedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      buyerName: buyerName ?? this.buyerName,
      sellerName: sellerName ?? this.sellerName,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'buyer_pharmacy_id': buyerPharmacyId,
    'seller_pharmacy_id': sellerPharmacyId,
    'status': status,
    'total_amount': totalAmount,
    if (notes != null) 'notes': notes,
    if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
    if (confirmedAt != null) 'confirmed_at': confirmedAt!.toIso8601String(),
    if (deliveredAt != null) 'delivered_at': deliveredAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory B2BOrder.fromJson(Map<String, dynamic> json) => B2BOrder(
    id: json['id'] as String,
    buyerPharmacyId: json['buyer_pharmacy_id'] as String,
    sellerPharmacyId: json['seller_pharmacy_id'] as String,
    status: json['status'] as String,
    totalAmount: json['total_amount'] as int,
    notes: json['notes'] as String?,
    submittedAt: json['submitted_at'] != null
        ? DateTime.parse(json['submitted_at'] as String)
        : null,
    confirmedAt: json['confirmed_at'] != null
        ? DateTime.parse(json['confirmed_at'] as String)
        : null,
    deliveredAt: json['delivered_at'] != null
        ? DateTime.parse(json['delivered_at'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    buyerName: json['buyers'] != null
        ? (json['buyers'] as Map<String, dynamic>)['name'] as String?
        : null,
    sellerName: json['sellers'] != null
        ? (json['sellers'] as Map<String, dynamic>)['name'] as String?
        : null,
    items: json['items'] != null
        ? (json['items'] as List)
              .map((e) => B2BOrderItem.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    buyerPharmacyId,
    sellerPharmacyId,
    status,
    totalAmount,
    notes,
    submittedAt,
    confirmedAt,
    deliveredAt,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    buyerName,
    sellerName,
    items,
  ];

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'submitted':
        return 'Soumise';
      case 'confirmed':
        return 'Confirmée';
      case 'shipped':
        return 'Expédiée';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  String get statusIcon {
    switch (status) {
      case 'draft':
        return '📄';
      case 'submitted':
        return '📤';
      case 'confirmed':
        return '✅';
      case 'shipped':
        return '🚚';
      case 'delivered':
        return '📦';
      case 'cancelled':
        return '❌';
      default:
        return '📋';
    }
  }

  bool get isActive => status != 'delivered' && status != 'cancelled';
}

class B2BOrderItem extends Equatable {
  final String id;
  final String orderId;
  final String? offerId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final DateTime createdAt;
  final String? gsgId;
  final String? gsgOrgId;

  const B2BOrderItem({
    required this.id,
    required this.orderId,
    this.offerId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    this.gsgId,
    this.gsgOrgId,
  });

  // Phase 4 (module marketplace) : copyWith() jamais écrit alors qu'appelé
  // par MarketplaceService - même motif que CHN-10/ASR-8/HomecareAvailability
  // Slot/AvailabilitySlot déjà rencontrés dans ce projet.
  B2BOrderItem copyWith({
    String? id,
    String? orderId,
    String? offerId,
    String? productName,
    int? quantity,
    int? unitPrice,
    int? totalPrice,
    DateTime? createdAt,
    String? gsgId,
    String? gsgOrgId,
  }) => B2BOrderItem(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    offerId: offerId ?? this.offerId,
    productName: productName ?? this.productName,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    totalPrice: totalPrice ?? this.totalPrice,
    createdAt: createdAt ?? this.createdAt,
    gsgId: gsgId ?? this.gsgId,
    gsgOrgId: gsgOrgId ?? this.gsgOrgId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    if (offerId != null) 'offer_id': offerId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    'created_at': createdAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory B2BOrderItem.fromJson(Map<String, dynamic> json) => B2BOrderItem(
    id: json['id'] as String,
    orderId: json['order_id'] as String,
    offerId: json['offer_id'] as String?,
    productName: json['product_name'] as String,
    quantity: json['quantity'] as int,
    unitPrice: json['unit_price'] as int,
    totalPrice: json['total_price'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    orderId,
    offerId,
    productName,
    quantity,
    unitPrice,
    totalPrice,
    createdAt,
    gsgId,
    gsgOrgId,
  ];
}
