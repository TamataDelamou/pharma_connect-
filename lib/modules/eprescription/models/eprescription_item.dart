import 'package:equatable/equatable.dart';

class EPrescriptionItem extends Equatable {
  final String id;
  final String eprescriptionId;
  final String? productId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final int quantity;
  final String? instructions;
  final bool isSubstitutionAllowed;
  final int? daysSupply;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  const EPrescriptionItem({
    required this.id,
    required this.eprescriptionId,
    this.productId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.quantity,
    this.instructions,
    this.isSubstitutionAllowed = false,
    this.daysSupply,
    required this.createdAt,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
  });

  EPrescriptionItem copyWith({
    String? id,
    String? eprescriptionId,
    String? productId,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? duration,
    int? quantity,
    String? instructions,
    bool? isSubstitutionAllowed,
    int? daysSupply,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return EPrescriptionItem(
      id: id ?? this.id,
      eprescriptionId: eprescriptionId ?? this.eprescriptionId,
      productId: productId ?? this.productId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      quantity: quantity ?? this.quantity,
      instructions: instructions ?? this.instructions,
      isSubstitutionAllowed:
          isSubstitutionAllowed ?? this.isSubstitutionAllowed,
      daysSupply: daysSupply ?? this.daysSupply,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eprescription_id': eprescriptionId,
    if (productId != null) 'product_id': productId,
    'medication_name': medicationName,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    'quantity': quantity,
    if (instructions != null) 'instructions': instructions,
    'is_substitution_allowed': isSubstitutionAllowed,
    if (daysSupply != null) 'days_supply': daysSupply,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory EPrescriptionItem.fromJson(Map<String, dynamic> json) =>
      EPrescriptionItem(
        id: json['id'] as String,
        eprescriptionId: json['eprescription_id'] as String,
        productId: json['product_id'] as String?,
        medicationName: json['medication_name'] as String,
        dosage: json['dosage'] as String,
        frequency: json['frequency'] as String,
        duration: json['duration'] as String,
        quantity: json['quantity'] as int,
        instructions: json['instructions'] as String?,
        isSubstitutionAllowed:
            json['is_substitution_allowed'] as bool? ?? false,
        daysSupply: json['days_supply'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    eprescriptionId,
    productId,
    medicationName,
    dosage,
    frequency,
    duration,
    quantity,
    instructions,
    isSubstitutionAllowed,
    daysSupply,
    createdAt,
    updatedAt,
    gsgId,
    gsgOrgId,
  ];
}
