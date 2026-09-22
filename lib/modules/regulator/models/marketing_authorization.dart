import 'package:equatable/equatable.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4 : modèle pour la table
// `marketing_authorizations` (AMM), jusqu'ici entièrement orpheline.
class MarketingAuthorization extends Equatable {
  final String id;
  final String? productId;
  final String productName;
  final String manufacturer;
  final String authorizationNumber;
  final String issuingBody;
  final String status; // pending, approved, suspended, revoked, expired
  final DateTime? approvedAt;
  final DateTime? expiryDate;
  final String? indications;
  final String? contraindications;
  final String? sideEffects;
  final String? dosageInstructions;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  const MarketingAuthorization({
    required this.id,
    this.productId,
    required this.productName,
    required this.manufacturer,
    required this.authorizationNumber,
    required this.issuingBody,
    required this.status,
    this.approvedAt,
    this.expiryDate,
    this.indications,
    this.contraindications,
    this.sideEffects,
    this.dosageInstructions,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  MarketingAuthorization copyWith({
    String? id,
    String? productId,
    String? productName,
    String? manufacturer,
    String? authorizationNumber,
    String? issuingBody,
    String? status,
    DateTime? approvedAt,
    DateTime? expiryDate,
    String? indications,
    String? contraindications,
    String? sideEffects,
    String? dosageInstructions,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return MarketingAuthorization(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      manufacturer: manufacturer ?? this.manufacturer,
      authorizationNumber: authorizationNumber ?? this.authorizationNumber,
      issuingBody: issuingBody ?? this.issuingBody,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      indications: indications ?? this.indications,
      contraindications: contraindications ?? this.contraindications,
      sideEffects: sideEffects ?? this.sideEffects,
      dosageInstructions: dosageInstructions ?? this.dosageInstructions,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (productId != null) 'product_id': productId,
    'product_name': productName,
    'manufacturer': manufacturer,
    'authorization_number': authorizationNumber,
    'issuing_body': issuingBody,
    'status': status,
    if (approvedAt != null) 'approved_at': approvedAt!.toIso8601String(),
    if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String(),
    if (indications != null) 'indications': indications,
    if (contraindications != null) 'contraindications': contraindications,
    if (sideEffects != null) 'side_effects': sideEffects,
    if (dosageInstructions != null) 'dosage_instructions': dosageInstructions,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
  };

  factory MarketingAuthorization.fromJson(Map<String, dynamic> json) =>
      MarketingAuthorization(
        id: json['id'] as String,
        productId: json['product_id'] as String?,
        productName: json['product_name'] as String,
        manufacturer: json['manufacturer'] as String,
        authorizationNumber: json['authorization_number'] as String,
        issuingBody: json['issuing_body'] as String,
        status: json['status'] as String,
        approvedAt: json['approved_at'] != null
            ? DateTime.parse(json['approved_at'] as String)
            : null,
        expiryDate: json['expiry_date'] != null
            ? DateTime.parse(json['expiry_date'] as String)
            : null,
        indications: json['indications'] as String?,
        contraindications: json['contraindications'] as String?,
        sideEffects: json['side_effects'] as String?,
        dosageInstructions: json['dosage_instructions'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    manufacturer,
    authorizationNumber,
    issuingBody,
    status,
    approvedAt,
    expiryDate,
    indications,
    contraindications,
    sideEffects,
    dosageInstructions,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
  ];

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvée';
      case 'suspended':
        return 'Suspendue';
      case 'revoked':
        return 'Révoquée';
      case 'expired':
        return 'Expirée';
      default:
        return status;
    }
  }
}
