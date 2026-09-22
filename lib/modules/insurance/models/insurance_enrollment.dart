import 'package:equatable/equatable.dart';

class InsuranceEnrollment extends Equatable {
  final String id;
  final String patientId;
  final String planId;
  final String policyNumber;
  final String? memberNumber;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // active, suspended, expired, cancelled
  final int? coveragePercentage;
  final int? annualLimit;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived fields
  final String? planName;
  final String? companyName;
  final String? companyId;
  final String? patientName;

  const InsuranceEnrollment({
    required this.id,
    required this.patientId,
    required this.planId,
    required this.policyNumber,
    this.memberNumber,
    required this.startDate,
    this.endDate,
    required this.status,
    this.coveragePercentage,
    this.annualLimit,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.planName,
    this.companyName,
    this.companyId,
    this.patientName,
  });

  // ASR-3/ASR-8 (audit Module 24, Étape 2/3, 30/08/2026) : copyWith absent
  // alors qu'il est appelé par InsuranceService.createEnrollment() /
  // updateEnrollment() (`enrollment.copyWith(...)`) — défaut bloquant la
  // compilation du module dès qu'une création ou modification d'adhésion est
  // exercée, découvert en préparant le correctif de l'écran de création
  // (ASR-3). Signature calquée sur le patron déjà utilisé par
  // ReimbursementTracking.copyWith() dans ce même module.
  InsuranceEnrollment copyWith({
    String? id,
    String? patientId,
    String? planId,
    String? policyNumber,
    String? memberNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? coveragePercentage,
    int? annualLimit,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? planName,
    String? companyName,
    String? companyId,
    String? patientName,
  }) {
    return InsuranceEnrollment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      planId: planId ?? this.planId,
      policyNumber: policyNumber ?? this.policyNumber,
      memberNumber: memberNumber ?? this.memberNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      coveragePercentage: coveragePercentage ?? this.coveragePercentage,
      annualLimit: annualLimit ?? this.annualLimit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      planName: planName ?? this.planName,
      companyName: companyName ?? this.companyName,
      companyId: companyId ?? this.companyId,
      patientName: patientName ?? this.patientName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'plan_id': planId,
    'policy_number': policyNumber,
    if (memberNumber != null) 'member_number': memberNumber,
    'start_date': startDate.toIso8601String(),
    if (endDate != null) 'end_date': endDate!.toIso8601String(),
    'status': status,
    if (coveragePercentage != null) 'coverage_percentage': coveragePercentage,
    if (annualLimit != null) 'annual_limit': annualLimit,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory InsuranceEnrollment.fromJson(Map<String, dynamic> json) =>
      InsuranceEnrollment(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        planId: json['plan_id'] as String,
        policyNumber: json['policy_number'] as String,
        memberNumber: json['member_number'] as String?,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        status: json['status'] as String,
        coveragePercentage: json['coverage_percentage'] as int?,
        annualLimit: json['annual_limit'] as int?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
        // ASR-6 (audit Module 24) : la compagnie est désormais lue depuis l'embed
        // imbriqué plans.companies (voir InsuranceService.getEnrollment[sForPatient]),
        // plus depuis un ancien champ top-level 'companies' que PostgREST ne pouvait
        // de toute façon jamais résoudre avec l'indice de relation d'origine.
        planName: json['plans'] != null
            ? (json['plans'] as Map<String, dynamic>)['name'] as String?
            : null,
        companyName:
            json['plans'] != null &&
                (json['plans'] as Map<String, dynamic>)['companies'] != null
            ? ((json['plans'] as Map<String, dynamic>)['companies']
                    as Map<String, dynamic>)['name']
                as String?
            : null,
        companyId:
            json['plans'] != null &&
                (json['plans'] as Map<String, dynamic>)['companies'] != null
            ? ((json['plans'] as Map<String, dynamic>)['companies']
                    as Map<String, dynamic>)['id']
                as String?
            : null,
        patientName: json['patients'] != null
            ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
            : null,
      );

  @override
  List<Object?> get props => [
    id,
    patientId,
    planId,
    policyNumber,
    memberNumber,
    startDate,
    endDate,
    status,
    coveragePercentage,
    annualLimit,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    planName,
    companyName,
    companyId,
    patientName,
  ];

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'suspended':
        return 'Suspendu';
      case 'expired':
        return 'Expiré';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  bool get isActive => status == 'active';
  bool get isExpired =>
      status == 'expired' ||
      (endDate != null && endDate!.isBefore(DateTime.now()));
}
