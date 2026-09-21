import 'package:equatable/equatable.dart';

class ProfessionalQualification extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? issuingBody;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  const ProfessionalQualification({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.issuingBody,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    if (description != null) 'description': description,
    if (issuingBody != null) 'issuing_body': issuingBody,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory ProfessionalQualification.fromJson(Map<String, dynamic> json) =>
      ProfessionalQualification(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        issuingBody: json['issuing_body'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    description,
    issuingBody,
    isActive,
    createdAt,
    updatedAt,
    gsgId,
    gsgOrgId,
  ];
}
