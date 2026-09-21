import 'package:equatable/equatable.dart';

class InsuranceCompany extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String type; // private, public, mutual, international
  final String? logoUrl;
  final String? website;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const InsuranceCompany({
    required this.id,
    required this.name,
    this.code,
    required this.type,
    this.logoUrl,
    this.website,
    this.phone,
    this.email,
    this.address,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (code != null) 'code': code,
    'type': type,
    if (logoUrl != null) 'logo_url': logoUrl,
    if (website != null) 'website': website,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (address != null) 'address': address,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory InsuranceCompany.fromJson(Map<String, dynamic> json) =>
      InsuranceCompany(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String?,
        type: json['type'] as String,
        logoUrl: json['logo_url'] as String?,
        website: json['website'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        isActive: json['is_active'] as bool? ?? true,
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
    name,
    code,
    type,
    logoUrl,
    website,
    phone,
    email,
    address,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get typeLabel {
    switch (type) {
      case 'private':
        return 'Assurance privée';
      case 'public':
        return 'Assurance publique';
      case 'mutual':
        return 'Mutuelle';
      case 'international':
        return 'Assurance internationale';
      default:
        return type;
    }
  }
}
