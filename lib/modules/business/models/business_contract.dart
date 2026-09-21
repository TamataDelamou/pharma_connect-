import 'package:equatable/equatable.dart';

class BusinessContract extends Equatable {
  final String id;
  final String companyId;
  final String contractNumber;
  final String title;
  final String? description;
  final String type; // supply, distribution, service, partnership, exclusivity
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // draft, active, expired, terminated, suspended
  final String? terms;
  final DateTime? signedAt;
  final String? signedBy;
  final String? contractUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const BusinessContract({
    required this.id,
    required this.companyId,
    required this.contractNumber,
    required this.title,
    this.description,
    required this.type,
    required this.startDate,
    this.endDate,
    this.status = 'draft',
    this.terms,
    this.signedAt,
    this.signedBy,
    this.contractUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  BusinessContract copyWith({
    String? id,
    String? companyId,
    String? contractNumber,
    String? title,
    String? description,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? terms,
    DateTime? signedAt,
    String? signedBy,
    String? contractUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return BusinessContract(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      contractNumber: contractNumber ?? this.contractNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      terms: terms ?? this.terms,
      signedAt: signedAt ?? this.signedAt,
      signedBy: signedBy ?? this.signedBy,
      contractUrl: contractUrl ?? this.contractUrl,
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
    'company_id': companyId,
    'contract_number': contractNumber,
    'title': title,
    if (description != null) 'description': description,
    'type': type,
    'start_date': startDate.toIso8601String().split('T').first,
    if (endDate != null)
      'end_date': endDate!.toIso8601String().split('T').first,
    'status': status,
    if (terms != null) 'terms': terms,
    if (signedAt != null) 'signed_at': signedAt!.toIso8601String(),
    if (signedBy != null) 'signed_by': signedBy,
    if (contractUrl != null) 'contract_url': contractUrl,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory BusinessContract.fromJson(Map<String, dynamic> json) =>
      BusinessContract(
        id: json['id'] as String,
        companyId: json['company_id'] as String,
        contractNumber: json['contract_number'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        type: json['type'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        status: json['status'] as String? ?? 'draft',
        terms: json['terms'] as String?,
        signedAt: json['signed_at'] != null
            ? DateTime.parse(json['signed_at'] as String)
            : null,
        signedBy: json['signed_by'] as String?,
        contractUrl: json['contract_url'] as String?,
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
    companyId,
    contractNumber,
    title,
    description,
    type,
    startDate,
    endDate,
    status,
    terms,
    signedAt,
    signedBy,
    contractUrl,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get typeLabel {
    switch (type) {
      case 'supply':
        return '📦 Approvisionnement';
      case 'distribution':
        return '📦 Distribution';
      case 'service':
        return '🛠️ Service';
      case 'partnership':
        return '🤝 Partenariat';
      case 'exclusivity':
        return '🔒 Exclusivité';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return '📝 Brouillon';
      case 'active':
        return '✅ Actif';
      case 'expired':
        return '⏰ Expiré';
      case 'terminated':
        return '🔚 Résilié';
      case 'suspended':
        return '⏸️ Suspendu';
      default:
        return status;
    }
  }

  bool get isActive =>
      status == 'active' &&
      (endDate == null || endDate!.isAfter(DateTime.now()));
}
