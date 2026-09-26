import 'package:equatable/equatable.dart';

class BusinessCompany extends Equatable {
  final String id;
  final String? gsgOrgId;
  final String name;
  final String? legalName;
  final String? registrationNumber;
  final String? taxId;
  final String
  type; // hospital, clinic, wholesaler, laboratory, pharmacy_chain, insurance, other
  final String status; // active, inactive, pending, suspended, archived
  final String? address;
  final String? city;
  final String? country;
  final String? phone;
  final String? email;
  final String? website;
  final String? contactPersonName;
  final String? contactPersonPhone;
  final String? contactPersonEmail;
  final String? notes;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;

  const BusinessCompany({
    required this.id,
    this.gsgOrgId,
    required this.name,
    this.legalName,
    this.registrationNumber,
    this.taxId,
    required this.type,
    this.status = 'active',
    this.address,
    this.city,
    this.country,
    this.phone,
    this.email,
    this.website,
    this.contactPersonName,
    this.contactPersonPhone,
    this.contactPersonEmail,
    this.notes,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
  });

  BusinessCompany copyWith({
    String? id,
    String? gsgOrgId,
    String? name,
    String? legalName,
    String? registrationNumber,
    String? taxId,
    String? type,
    String? status,
    String? address,
    String? city,
    String? country,
    String? phone,
    String? email,
    String? website,
    String? contactPersonName,
    String? contactPersonPhone,
    String? contactPersonEmail,
    String? notes,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
  }) {
    return BusinessCompany(
      id: id ?? this.id,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      taxId: taxId ?? this.taxId,
      type: type ?? this.type,
      status: status ?? this.status,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      contactPersonEmail: contactPersonEmail ?? this.contactPersonEmail,
      notes: notes ?? this.notes,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
    'name': name,
    if (legalName != null) 'legal_name': legalName,
    if (registrationNumber != null) 'registration_number': registrationNumber,
    if (taxId != null) 'tax_id': taxId,
    'type': type,
    'status': status,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (country != null) 'country': country,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (website != null) 'website': website,
    if (contactPersonName != null) 'contact_person_name': contactPersonName,
    if (contactPersonPhone != null) 'contact_person_phone': contactPersonPhone,
    if (contactPersonEmail != null) 'contact_person_email': contactPersonEmail,
    if (notes != null) 'notes': notes,
    if (logoUrl != null) 'logo_url': logoUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
  };

  factory BusinessCompany.fromJson(Map<String, dynamic> json) =>
      BusinessCompany(
        id: json['id'] as String,
        gsgOrgId: json['gsg_org_id'] as String?,
        name: json['name'] as String,
        legalName: json['legal_name'] as String?,
        registrationNumber: json['registration_number'] as String?,
        taxId: json['tax_id'] as String?,
        type: json['type'] as String,
        status: json['status'] as String? ?? 'active',
        address: json['address'] as String?,
        city: json['city'] as String?,
        country: json['country'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        website: json['website'] as String?,
        contactPersonName: json['contact_person_name'] as String?,
        contactPersonPhone: json['contact_person_phone'] as String?,
        contactPersonEmail: json['contact_person_email'] as String?,
        notes: json['notes'] as String?,
        logoUrl: json['logo_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    gsgOrgId,
    name,
    legalName,
    registrationNumber,
    taxId,
    type,
    status,
    address,
    city,
    country,
    phone,
    email,
    website,
    contactPersonName,
    contactPersonPhone,
    contactPersonEmail,
    notes,
    logoUrl,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
  ];

  String get typeLabel {
    switch (type) {
      case 'hospital':
        return '🏥 Hôpital';
      case 'clinic':
        return '🏥 Clinique';
      case 'wholesaler':
        return '📦 Grossiste';
      case 'laboratory':
        return '🔬 Laboratoire';
      case 'pharmacy_chain':
        return '💊 Chaîne de pharmacies';
      case 'insurance':
        return '🛡️ Assurance';
      case 'other':
        return '📋 Autre';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return '✅ Actif';
      case 'inactive':
        return '⛔ Inactif';
      case 'pending':
        return '⏳ En attente';
      case 'suspended':
        return '🚫 Suspendu';
      case 'archived':
        return '📦 Archivé';
      default:
        return status;
    }
  }
}
