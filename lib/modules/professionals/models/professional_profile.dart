import 'package:equatable/equatable.dart';

class ProfessionalProfile extends Equatable {
  final String id;
  final String specialty;
  final List<String> qualifications;
  final String? licenseNumber;
  final String? licenseIssuingBody;
  final DateTime? licenseExpiryDate;
  final int? yearsOfExperience;
  final int? consultationFee;
  final int? homeVisitFee;
  final bool isAcceptingNewPatients;
  final String? bio;
  final int consultationDurationMinutes;
  final List<String> languagesSpoken;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? profilePhotoUrl;
  final bool isVerified;
  final String? verificationStatus; // pending, verified, rejected
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived from profiles join
  final String? fullName;
  final String? phone;
  final String? email;

  const ProfessionalProfile({
    required this.id,
    required this.specialty,
    this.qualifications = const [],
    this.licenseNumber,
    this.licenseIssuingBody,
    this.licenseExpiryDate,
    this.yearsOfExperience,
    this.consultationFee,
    this.homeVisitFee,
    this.isAcceptingNewPatients = true,
    this.bio,
    this.consultationDurationMinutes = 30,
    this.languagesSpoken = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.profilePhotoUrl,
    this.isVerified = false,
    this.verificationStatus,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.fullName,
    this.phone,
    this.email,
  });

  ProfessionalProfile copyWith({
    String? id,
    String? specialty,
    List<String>? qualifications,
    String? licenseNumber,
    String? licenseIssuingBody,
    DateTime? licenseExpiryDate,
    int? yearsOfExperience,
    int? consultationFee,
    int? homeVisitFee,
    bool? isAcceptingNewPatients,
    String? bio,
    int? consultationDurationMinutes,
    List<String>? languagesSpoken,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? profilePhotoUrl,
    bool? isVerified,
    String? verificationStatus,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? fullName,
    String? phone,
    String? email,
  }) {
    return ProfessionalProfile(
      id: id ?? this.id,
      specialty: specialty ?? this.specialty,
      qualifications: qualifications ?? this.qualifications,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseIssuingBody: licenseIssuingBody ?? this.licenseIssuingBody,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      consultationFee: consultationFee ?? this.consultationFee,
      homeVisitFee: homeVisitFee ?? this.homeVisitFee,
      isAcceptingNewPatients:
          isAcceptingNewPatients ?? this.isAcceptingNewPatients,
      bio: bio ?? this.bio,
      consultationDurationMinutes:
          consultationDurationMinutes ?? this.consultationDurationMinutes,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'specialty': specialty,
    'qualifications': qualifications,
    if (licenseNumber != null) 'license_number': licenseNumber,
    if (licenseIssuingBody != null) 'license_issuing_body': licenseIssuingBody,
    if (licenseExpiryDate != null)
      'license_expiry_date': licenseExpiryDate!.toIso8601String(),
    if (yearsOfExperience != null) 'years_of_experience': yearsOfExperience,
    if (consultationFee != null) 'consultation_fee': consultationFee,
    if (homeVisitFee != null) 'home_visit_fee': homeVisitFee,
    'is_accepting_new_patients': isAcceptingNewPatients,
    if (bio != null) 'bio': bio,
    'consultation_duration_minutes': consultationDurationMinutes,
    'languages_spoken': languagesSpoken,
    if (emergencyContactName != null)
      'emergency_contact_name': emergencyContactName,
    if (emergencyContactPhone != null)
      'emergency_contact_phone': emergencyContactPhone,
    if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
    'is_verified': isVerified,
    if (verificationStatus != null) 'verification_status': verificationStatus,
    if (rejectionReason != null) 'rejection_reason': rejectionReason,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory ProfessionalProfile.fromJson(
    Map<String, dynamic> json,
  ) => ProfessionalProfile(
    id: json['id'] as String,
    specialty: json['specialty'] as String? ?? '',
    qualifications: (json['qualifications'] as List?)?.cast<String>() ?? [],
    licenseNumber: json['license_number'] as String?,
    licenseIssuingBody: json['license_issuing_body'] as String?,
    licenseExpiryDate: json['license_expiry_date'] != null
        ? DateTime.parse(json['license_expiry_date'] as String)
        : null,
    yearsOfExperience: json['years_of_experience'] as int?,
    consultationFee: json['consultation_fee'] as int?,
    homeVisitFee: json['home_visit_fee'] as int?,
    isAcceptingNewPatients: json['is_accepting_new_patients'] as bool? ?? true,
    bio: json['bio'] as String?,
    consultationDurationMinutes:
        json['consultation_duration_minutes'] as int? ?? 30,
    languagesSpoken: (json['languages_spoken'] as List?)?.cast<String>() ?? [],
    emergencyContactName: json['emergency_contact_name'] as String?,
    emergencyContactPhone: json['emergency_contact_phone'] as String?,
    profilePhotoUrl: json['profile_photo_url'] as String?,
    isVerified: json['is_verified'] as bool? ?? false,
    verificationStatus: json['verification_status'] as String?,
    rejectionReason: json['rejection_reason'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    fullName: json['profiles'] != null
        ? (json['profiles'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    phone: json['profiles'] != null
        ? (json['profiles'] as Map<String, dynamic>)['phone'] as String?
        : null,
    email: json['profiles'] != null
        ? (json['profiles'] as Map<String, dynamic>)['email'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    specialty,
    qualifications,
    licenseNumber,
    licenseIssuingBody,
    licenseExpiryDate,
    yearsOfExperience,
    consultationFee,
    homeVisitFee,
    isAcceptingNewPatients,
    bio,
    consultationDurationMinutes,
    languagesSpoken,
    emergencyContactName,
    emergencyContactPhone,
    profilePhotoUrl,
    isVerified,
    verificationStatus,
    rejectionReason,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    fullName,
    phone,
    email,
  ];
}
