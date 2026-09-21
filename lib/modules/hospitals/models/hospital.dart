import 'package:equatable/equatable.dart';

class Hospital extends Equatable {
  final String id;
  final String? gsgOrgId;
  final String name;
  final String? typeId;
  final String? code;
  final String address;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? phone;
  final String? email;
  final String? website;
  final double? latitude;
  final double? longitude;
  final String? emergencyPhone;
  final int? capacity;
  final bool isActive;
  final bool isEmergencyAvailable;
  final bool isLabAvailable;
  final bool isImagingAvailable;
  final bool isPharmacyAvailable;
  final String? description;
  final String? logoUrl;
  final String? licenseNumber;
  final String? licenseIssuingBody;
  final DateTime? licenseExpiryDate;
  final String? accreditation;
  final DateTime? accreditationExpiryDate;
  final Map<String, dynamic> openingHours;
  final String? contactPersonName;
  final String? contactPersonPhone;
  final String? contactPersonEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;

  // Derived fields
  final String? typeName;
  final int? departmentCount;

  const Hospital({
    required this.id,
    this.gsgOrgId,
    required this.name,
    this.typeId,
    this.code,
    required this.address,
    this.city,
    this.postalCode,
    this.country,
    this.phone,
    this.email,
    this.website,
    this.latitude,
    this.longitude,
    this.emergencyPhone,
    this.capacity,
    this.isActive = true,
    this.isEmergencyAvailable = false,
    this.isLabAvailable = false,
    this.isImagingAvailable = false,
    this.isPharmacyAvailable = false,
    this.description,
    this.logoUrl,
    this.licenseNumber,
    this.licenseIssuingBody,
    this.licenseExpiryDate,
    this.accreditation,
    this.accreditationExpiryDate,
    this.openingHours = const {},
    this.contactPersonName,
    this.contactPersonPhone,
    this.contactPersonEmail,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.typeName,
    this.departmentCount,
  });

  Hospital copyWith({
    String? id,
    String? gsgOrgId,
    String? name,
    String? typeId,
    String? code,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? phone,
    String? email,
    String? website,
    double? latitude,
    double? longitude,
    String? emergencyPhone,
    int? capacity,
    bool? isActive,
    bool? isEmergencyAvailable,
    bool? isLabAvailable,
    bool? isImagingAvailable,
    bool? isPharmacyAvailable,
    String? description,
    String? logoUrl,
    String? licenseNumber,
    String? licenseIssuingBody,
    DateTime? licenseExpiryDate,
    String? accreditation,
    DateTime? accreditationExpiryDate,
    Map<String, dynamic>? openingHours,
    String? contactPersonName,
    String? contactPersonPhone,
    String? contactPersonEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? typeName,
    int? departmentCount,
  }) {
    return Hospital(
      id: id ?? this.id,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      name: name ?? this.name,
      typeId: typeId ?? this.typeId,
      code: code ?? this.code,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
      isEmergencyAvailable: isEmergencyAvailable ?? this.isEmergencyAvailable,
      isLabAvailable: isLabAvailable ?? this.isLabAvailable,
      isImagingAvailable: isImagingAvailable ?? this.isImagingAvailable,
      isPharmacyAvailable: isPharmacyAvailable ?? this.isPharmacyAvailable,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseIssuingBody: licenseIssuingBody ?? this.licenseIssuingBody,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      accreditation: accreditation ?? this.accreditation,
      accreditationExpiryDate:
          accreditationExpiryDate ?? this.accreditationExpiryDate,
      openingHours: openingHours ?? this.openingHours,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      contactPersonEmail: contactPersonEmail ?? this.contactPersonEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      typeName: typeName ?? this.typeName,
      departmentCount: departmentCount ?? this.departmentCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
    'name': name,
    if (typeId != null) 'type_id': typeId,
    if (code != null) 'code': code,
    'address': address,
    if (city != null) 'city': city,
    if (postalCode != null) 'postal_code': postalCode,
    if (country != null) 'country': country,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (website != null) 'website': website,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (emergencyPhone != null) 'emergency_phone': emergencyPhone,
    if (capacity != null) 'capacity': capacity,
    'is_active': isActive,
    'is_emergency_available': isEmergencyAvailable,
    'is_lab_available': isLabAvailable,
    'is_imaging_available': isImagingAvailable,
    'is_pharmacy_available': isPharmacyAvailable,
    if (description != null) 'description': description,
    if (logoUrl != null) 'logo_url': logoUrl,
    if (licenseNumber != null) 'license_number': licenseNumber,
    if (licenseIssuingBody != null) 'license_issuing_body': licenseIssuingBody,
    if (licenseExpiryDate != null)
      'license_expiry_date': licenseExpiryDate!.toIso8601String(),
    if (accreditation != null) 'accreditation': accreditation,
    if (accreditationExpiryDate != null)
      'accreditation_expiry_date': accreditationExpiryDate!.toIso8601String(),
    'opening_hours': openingHours,
    if (contactPersonName != null) 'contact_person_name': contactPersonName,
    if (contactPersonPhone != null) 'contact_person_phone': contactPersonPhone,
    if (contactPersonEmail != null) 'contact_person_email': contactPersonEmail,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
  };

  factory Hospital.fromJson(Map<String, dynamic> json) => Hospital(
    id: json['id'] as String,
    gsgOrgId: json['gsg_org_id'] as String?,
    name: json['name'] as String,
    typeId: json['type_id'] as String?,
    code: json['code'] as String?,
    address: json['address'] as String,
    city: json['city'] as String?,
    postalCode: json['postal_code'] as String?,
    country: json['country'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    website: json['website'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    emergencyPhone: json['emergency_phone'] as String?,
    capacity: json['capacity'] as int?,
    isActive: json['is_active'] as bool? ?? true,
    isEmergencyAvailable: json['is_emergency_available'] as bool? ?? false,
    isLabAvailable: json['is_lab_available'] as bool? ?? false,
    isImagingAvailable: json['is_imaging_available'] as bool? ?? false,
    isPharmacyAvailable: json['is_pharmacy_available'] as bool? ?? false,
    description: json['description'] as String?,
    logoUrl: json['logo_url'] as String?,
    licenseNumber: json['license_number'] as String?,
    licenseIssuingBody: json['license_issuing_body'] as String?,
    licenseExpiryDate: json['license_expiry_date'] != null
        ? DateTime.parse(json['license_expiry_date'] as String)
        : null,
    accreditation: json['accreditation'] as String?,
    accreditationExpiryDate: json['accreditation_expiry_date'] != null
        ? DateTime.parse(json['accreditation_expiry_date'] as String)
        : null,
    openingHours: json['opening_hours'] as Map<String, dynamic>? ?? {},
    contactPersonName: json['contact_person_name'] as String?,
    contactPersonPhone: json['contact_person_phone'] as String?,
    contactPersonEmail: json['contact_person_email'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    typeName: json['types'] != null
        ? (json['types'] as Map<String, dynamic>)['name'] as String?
        : null,
    departmentCount: json['departments'] != null
        ? (json['departments'] as List).length
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    gsgOrgId,
    name,
    typeId,
    code,
    address,
    city,
    postalCode,
    country,
    phone,
    email,
    website,
    latitude,
    longitude,
    emergencyPhone,
    capacity,
    isActive,
    isEmergencyAvailable,
    isLabAvailable,
    isImagingAvailable,
    isPharmacyAvailable,
    description,
    logoUrl,
    licenseNumber,
    licenseIssuingBody,
    licenseExpiryDate,
    accreditation,
    accreditationExpiryDate,
    openingHours,
    contactPersonName,
    contactPersonPhone,
    contactPersonEmail,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    typeName,
    departmentCount,
  ];
}
