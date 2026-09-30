/// C219 / D63 : accès d'urgence (« bris de glace ») d'un professionnel au
/// dossier de santé d'un patient pris en charge au triage. Lu par la RPC
/// `list_emergency_access()`.
class EmergencyAccess {
  final String id;
  final String patientId;
  final String? patientName;
  final String professionalId;
  final String? professionalName;
  final String? hospitalName;
  final String reason;
  final DateTime grantedAt;
  final DateTime expiresAt;
  final DateTime? endedAt;
  final bool isActive;

  const EmergencyAccess({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.professionalId,
    this.professionalName,
    this.hospitalName,
    required this.reason,
    required this.grantedAt,
    required this.expiresAt,
    this.endedAt,
    required this.isActive,
  });

  factory EmergencyAccess.fromJson(Map<String, dynamic> json) {
    return EmergencyAccess(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String?,
      professionalId: json['professional_id'] as String,
      professionalName: json['professional_name'] as String?,
      hospitalName: json['hospital_name'] as String?,
      reason: json['reason'] as String? ?? '',
      grantedAt: DateTime.parse(json['granted_at'] as String).toLocal(),
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String).toLocal(),
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}
