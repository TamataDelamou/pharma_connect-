import 'package:equatable/equatable.dart';

class SolidarityProgram extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String
  type; // free_medication, subsidized_care, emergency_aid, health_education
  final String? pharmacyId;
  final DateTime startDate;
  final DateTime? endDate;
  final int? budget;
  final int usedBudget;
  final bool isActive;
  final Map<String, dynamic> eligibilityCriteria;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? pharmacyName;
  final int? beneficiariesCount;

  const SolidarityProgram({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.pharmacyId,
    required this.startDate,
    this.endDate,
    this.budget,
    this.usedBudget = 0,
    this.isActive = true,
    this.eligibilityCriteria = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.pharmacyName,
    this.beneficiariesCount,
  });

  SolidarityProgram copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    String? pharmacyId,
    DateTime? startDate,
    DateTime? endDate,
    int? budget,
    int? usedBudget,
    bool? isActive,
    Map<String, dynamic>? eligibilityCriteria,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? pharmacyName,
    int? beneficiariesCount,
  }) => SolidarityProgram(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    pharmacyId: pharmacyId ?? this.pharmacyId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    budget: budget ?? this.budget,
    usedBudget: usedBudget ?? this.usedBudget,
    isActive: isActive ?? this.isActive,
    eligibilityCriteria: eligibilityCriteria ?? this.eligibilityCriteria,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    gsgId: gsgId ?? this.gsgId,
    gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    pharmacyName: pharmacyName ?? this.pharmacyName,
    beneficiariesCount: beneficiariesCount ?? this.beneficiariesCount,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'type': type,
    if (pharmacyId != null) 'pharmacy_id': pharmacyId,
    'start_date': startDate.toIso8601String(),
    if (endDate != null) 'end_date': endDate!.toIso8601String(),
    if (budget != null) 'budget': budget,
    'used_budget': usedBudget,
    'is_active': isActive,
    'eligibility_criteria': eligibilityCriteria,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory SolidarityProgram.fromJson(Map<String, dynamic> json) =>
      SolidarityProgram(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        type: json['type'] as String,
        pharmacyId: json['pharmacy_id'] as String?,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        budget: json['budget'] as int?,
        usedBudget: json['used_budget'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        eligibilityCriteria:
            json['eligibility_criteria'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
        pharmacyName: json['pharmacies'] != null
            ? (json['pharmacies'] as Map<String, dynamic>)['name'] as String?
            : null,
        beneficiariesCount: json['beneficiaries'] != null
            ? (json['beneficiaries'] as List).length
            : null,
      );

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    pharmacyId,
    startDate,
    endDate,
    budget,
    usedBudget,
    isActive,
    eligibilityCriteria,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    pharmacyName,
    beneficiariesCount,
  ];

  String get typeLabel {
    switch (type) {
      case 'free_medication':
        return 'Médicaments gratuits';
      case 'subsidized_care':
        return 'Soins subventionnés';
      case 'emergency_aid':
        return 'Aide d\'urgence';
      case 'health_education':
        return 'Éducation sanitaire';
      default:
        return type;
    }
  }

  int get availableBudget => (budget ?? 0) - usedBudget;
  bool get hasBudget => budget != null && availableBudget > 0;
}
