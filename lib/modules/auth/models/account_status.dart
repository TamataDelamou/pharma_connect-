/// C213 / D64 : état du compte connecté, lu par la RPC `my_account_status()`.
/// Le serveur le calcule avec la même règle que les droits
/// (`has_verified_role`) : un rôle non vérifié n'ouvre aucun droit, et
/// l'application se comporte alors comme pour un patient, avec un bandeau.
enum AccountState {
  patient,
  verified,
  pendingReview,
  professionalProfileMissing,
  professionalRejected,
  noPharmacy,
  pharmacyApplicationPending,
  pharmacyApplicationRejected,
  pharmacyInactive,
  unknown,
}

AccountState _parseState(String? value) {
  switch (value) {
    case 'patient':
      return AccountState.patient;
    case 'verified':
      return AccountState.verified;
    case 'pending_review':
      return AccountState.pendingReview;
    case 'professional_profile_missing':
      return AccountState.professionalProfileMissing;
    case 'professional_rejected':
      return AccountState.professionalRejected;
    case 'no_pharmacy':
      return AccountState.noPharmacy;
    case 'pharmacy_application_pending':
      return AccountState.pharmacyApplicationPending;
    case 'pharmacy_application_rejected':
      return AccountState.pharmacyApplicationRejected;
    case 'pharmacy_inactive':
      return AccountState.pharmacyInactive;
    default:
      return AccountState.unknown;
  }
}

class AccountStatus {
  final String role;
  final AccountState state;

  /// Vrai si le rôle déclaré ouvre ses droits côté serveur (toujours vrai
  /// pour un patient).
  final bool roleActive;

  final String? pharmacyName;
  final String? pharmacyStatus;
  final String? applicationName;
  final String? applicationStatus;
  final String? professionalRejectionReason;
  final int pendingInvitations;

  /// Dernier refus d'un rôle par GSG (30 derniers jours) : rôle et motif.
  final String? rejectedRole;
  final String? rejectionReason;

  const AccountStatus({
    required this.role,
    required this.state,
    required this.roleActive,
    this.pharmacyName,
    this.pharmacyStatus,
    this.applicationName,
    this.applicationStatus,
    this.professionalRejectionReason,
    this.pendingInvitations = 0,
    this.rejectedRole,
    this.rejectionReason,
  });

  factory AccountStatus.fromJson(Map<String, dynamic> json) {
    final pharmacy = json['pharmacy'] as Map<String, dynamic>?;
    final application = json['application'] as Map<String, dynamic>?;
    final rejection = json['last_role_rejection'] as Map<String, dynamic>?;
    return AccountStatus(
      role: json['role'] as String? ?? 'patient',
      state: _parseState(json['state'] as String?),
      roleActive: json['role_active'] as bool? ?? false,
      pharmacyName: pharmacy?['name'] as String?,
      pharmacyStatus: pharmacy?['status'] as String?,
      applicationName: application?['name'] as String?,
      applicationStatus: application?['status'] as String?,
      professionalRejectionReason:
          json['professional_rejection_reason'] as String?,
      pendingInvitations: (json['pending_invitations'] as num?)?.toInt() ?? 0,
      rejectedRole: rejection?['role'] as String?,
      rejectionReason: rejection?['reason'] as String?,
    );
  }

  /// Pharmacien sans officine (ou candidature refusée) : peut accepter une
  /// invitation ou inscrire son officine.
  bool get canRegisterPharmacy =>
      state == AccountState.noPharmacy ||
      state == AccountState.pharmacyApplicationRejected;
}
