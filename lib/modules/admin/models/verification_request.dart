import '../../auth/models/user_role.dart';

/// C214 : compte à rôle déclaré et son état de vérification, tel que renvoyé
/// par la RPC `admin_list_verification_requests` (back-office GSG).
class VerificationRequest {
  final String userId;
  final String? fullName;
  final String? phone;
  final String? email;

  /// Rôle déclaré (`profiles.role`), `patient` s'il est vide.
  final String declaredRole;

  /// `pending`, `verified`, `rejected`, ou `none` (patient trouvé par la
  /// recherche, pour une attribution de rôle).
  final String verificationState;

  final DateTime? createdAt;
  final DateTime? roleVerifiedAt;
  final String? roleVerifiedByName;

  // Pharmacien : officine rattachée, sinon la plus récente dont il est
  // titulaire.
  final String? pharmacyId;
  final String? pharmacyName;
  final String? pharmacyStatus;

  // Professionnel de santé : fiche `professional_profiles` (null si absente).
  final String? professionalStatus;
  final String? licenseNumber;
  final String? licenseIssuingBody;
  final DateTime? licenseExpiryDate;
  final String? specialty;
  final String? rejectionReason;

  const VerificationRequest({
    required this.userId,
    required this.declaredRole,
    required this.verificationState,
    this.fullName,
    this.phone,
    this.email,
    this.createdAt,
    this.roleVerifiedAt,
    this.roleVerifiedByName,
    this.pharmacyId,
    this.pharmacyName,
    this.pharmacyStatus,
    this.professionalStatus,
    this.licenseNumber,
    this.licenseIssuingBody,
    this.licenseExpiryDate,
    this.specialty,
    this.rejectionReason,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final value = json[key];
      return value == null ? null : DateTime.tryParse(value as String);
    }

    return VerificationRequest(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      declaredRole: (json['declared_role'] as String?) ?? 'patient',
      verificationState: (json['verification_state'] as String?) ?? 'none',
      createdAt: date('created_at'),
      roleVerifiedAt: date('role_verified_at'),
      roleVerifiedByName: json['role_verified_by_name'] as String?,
      pharmacyId: json['pharmacy_id'] as String?,
      pharmacyName: json['pharmacy_name'] as String?,
      pharmacyStatus: json['pharmacy_status'] as String?,
      professionalStatus: json['professional_status'] as String?,
      licenseNumber: json['license_number'] as String?,
      licenseIssuingBody: json['license_issuing_body'] as String?,
      licenseExpiryDate: date('license_expiry_date'),
      specialty: json['specialty'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  /// Rôle déclaré sous forme d'énumération (patient si la valeur est inconnue).
  UserRole get role => UserRole.values.firstWhere(
    (r) => r.name == declaredRole,
    orElse: () => UserRole.patient,
  );

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return phone ?? email ?? userId;
  }

  bool get isPending => verificationState == 'pending';
  bool get isVerified => verificationState == 'verified';
  bool get isRejected => verificationState == 'rejected';

  /// Grossiste, livreur ou régulateur : validés par `admin_review_role`.
  bool get isInstitutionalRole =>
      role == UserRole.grossiste ||
      role == UserRole.livreur ||
      role == UserRole.regulateur;

  bool get isProfessional => role == UserRole.professionnel;
  bool get isPharmacist => role == UserRole.pharmacien;
  bool get isPatient => role == UserRole.patient;
}
