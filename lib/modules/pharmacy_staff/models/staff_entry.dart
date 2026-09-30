/// C209 : membre du personnel d'une officine ou invitation en attente, tel
/// que renvoyé par la RPC `pharmacy_list_staff`.
class StaffEntry {
  /// 'member' (rattaché) ou 'invitation' (en attente de réponse).
  final String kind;
  final String userId;
  final String? invitationId;
  final String? fullName;
  final String? phone;
  final bool isManager;
  final String status;
  final DateTime? since;

  const StaffEntry({
    required this.kind,
    required this.userId,
    required this.isManager,
    required this.status,
    this.invitationId,
    this.fullName,
    this.phone,
    this.since,
  });

  factory StaffEntry.fromJson(Map<String, dynamic> json) {
    final since = json['since'] as String?;
    return StaffEntry(
      kind: json['kind'] as String,
      userId: json['user_id'] as String,
      invitationId: json['invitation_id'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      isManager: json['is_manager'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      since: since == null ? null : DateTime.tryParse(since),
    );
  }

  bool get isMember => kind == 'member';
  bool get isPendingInvitation => kind == 'invitation';

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return phone ?? 'Compte sans nom';
  }
}

/// C209 : invitation reçue par l'utilisateur courant (RPC
/// `pharmacy_my_invitations`).
class StaffInvitation {
  final String invitationId;
  final String pharmacyId;
  final String pharmacyName;
  final String? pharmacyAddress;
  final String? invitedByName;
  final DateTime? createdAt;

  const StaffInvitation({
    required this.invitationId,
    required this.pharmacyId,
    required this.pharmacyName,
    this.pharmacyAddress,
    this.invitedByName,
    this.createdAt,
  });

  factory StaffInvitation.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] as String?;
    return StaffInvitation(
      invitationId: json['invitation_id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      pharmacyName: json['pharmacy_name'] as String? ?? 'Officine',
      pharmacyAddress: json['pharmacy_address'] as String?,
      invitedByName: json['invited_by_name'] as String?,
      createdAt: created == null ? null : DateTime.tryParse(created),
    );
  }
}
