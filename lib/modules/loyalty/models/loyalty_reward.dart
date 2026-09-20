import 'package:equatable/equatable.dart';

class LoyaltyReward extends Equatable {
  final String id;
  final String pharmacyId;
  final String name;
  final String? description;
  final int pointsRequired;
  final String type; // discount, product, service, gift
  final String? value;
  final String? imageUrl;
  final bool isActive;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const LoyaltyReward({
    required this.id,
    required this.pharmacyId,
    required this.name,
    this.description,
    required this.pointsRequired,
    required this.type,
    this.value,
    this.imageUrl,
    this.isActive = true,
    this.stockQuantity = 999,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  LoyaltyReward copyWith({
    String? id,
    String? pharmacyId,
    String? name,
    String? description,
    int? pointsRequired,
    String? type,
    String? value,
    String? imageUrl,
    bool? isActive,
    int? stockQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return LoyaltyReward(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      name: name ?? this.name,
      description: description ?? this.description,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      type: type ?? this.type,
      value: value ?? this.value,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      stockQuantity: stockQuantity ?? this.stockQuantity,
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
    'pharmacy_id': pharmacyId,
    'name': name,
    if (description != null) 'description': description,
    'points_required': pointsRequired,
    'type': type,
    if (value != null) 'value': value,
    if (imageUrl != null) 'image_url': imageUrl,
    'is_active': isActive,
    'stock_quantity': stockQuantity,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) => LoyaltyReward(
    id: json['id'] as String,
    pharmacyId: json['pharmacy_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    pointsRequired: json['points_required'] as int,
    type: json['type'] as String,
    value: json['value'] as String?,
    imageUrl: json['image_url'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    stockQuantity: json['stock_quantity'] as int? ?? 999,
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
    pharmacyId,
    name,
    description,
    pointsRequired,
    type,
    value,
    imageUrl,
    isActive,
    stockQuantity,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];
}
