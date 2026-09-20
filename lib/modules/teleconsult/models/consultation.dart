import 'package:equatable/equatable.dart';
import 'consultation_status.dart';

class Consultation extends Equatable {
  final String id;
  final String patientId;
  final String professionalId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final ConsultationStatus status;
  final String? reason;
  final String? notes;
  final String? meetingUrl;
  final String? patientFeedback;
  final String? professionalNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived fields (populated via join)
  final String? patientName;
  final String? patientPhone;
  final String? professionalName;
  final String? professionalSpecialty;

  const Consultation({
    required this.id,
    required this.patientId,
    required this.professionalId,
    required this.scheduledAt,
    this.durationMinutes = 30,
    required this.status,
    this.reason,
    this.notes,
    this.meetingUrl,
    this.patientFeedback,
    this.professionalNotes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
    this.patientPhone,
    this.professionalName,
    this.professionalSpecialty,
  });

  Consultation copyWith({
    String? id,
    String? patientId,
    String? professionalId,
    DateTime? scheduledAt,
    int? durationMinutes,
    ConsultationStatus? status,
    String? reason,
    String? notes,
    String? meetingUrl,
    String? patientFeedback,
    String? professionalNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
    String? patientPhone,
    String? professionalName,
    String? professionalSpecialty,
  }) {
    return Consultation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      professionalId: professionalId ?? this.professionalId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      patientFeedback: patientFeedback ?? this.patientFeedback,
      professionalNotes: professionalNotes ?? this.professionalNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      professionalName: professionalName ?? this.professionalName,
      professionalSpecialty:
          professionalSpecialty ?? this.professionalSpecialty,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'professional_id': professionalId,
    'scheduled_at': scheduledAt.toIso8601String(),
    'duration_minutes': durationMinutes,
    'status': status.name,
    if (reason != null) 'reason': reason,
    if (notes != null) 'notes': notes,
    if (meetingUrl != null) 'meeting_url': meetingUrl,
    if (patientFeedback != null) 'patient_feedback': patientFeedback,
    if (professionalNotes != null) 'professional_notes': professionalNotes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory Consultation.fromJson(Map<String, dynamic> json) => Consultation(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    professionalId: json['professional_id'] as String,
    scheduledAt: DateTime.parse(json['scheduled_at'] as String),
    durationMinutes: json['duration_minutes'] as int? ?? 30,
    status: ConsultationStatus.values.firstWhere(
      (e) => e.name == (json['status'] as String),
      orElse: () => ConsultationStatus.pending,
    ),
    reason: json['reason'] as String?,
    notes: json['notes'] as String?,
    meetingUrl: json['meeting_url'] as String?,
    patientFeedback: json['patient_feedback'] as String?,
    professionalNotes: json['professional_notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    patientName: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    patientPhone: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['phone'] as String?
        : null,
    professionalName: json['professionals'] != null
        ? (json['professionals'] as Map<String, dynamic>)['full_name']
              as String?
        : null,
    // Audit Module 15 (CNS, 29/08/2026) : `specialty` ne vit pas sur
    // `profiles` (colonne inexistante) mais sur `professional_profiles`,
    // embarquée en second niveau — voir teleconsult_service.dart. La
    // relation professional_profiles.id -> profiles.id étant un-à-un,
    // PostgREST la renvoie comme un objet, pas une liste.
    // Phase 4 (module teleconsult) : la version précédente combinait un
    // opérateur d'indexation null-aware (`?[...]`) directement après une
    // expression `as`, ce que la grammaire Dart n'autorise pas sans
    // parenthéser explicitement chaque étape - défaut de compilation
    // (parse error), jamais détecté faute de compilateur exécuté à la
    // clôture du Module 15/CNS. Réécrit en chaînage `?[...]` explicite,
    // qui rend d'ailleurs inutile la vérification manuelle `!= null` déjà
    // faite par l'opérateur lui-même.
    professionalSpecialty:
        ((json['professionals'] as Map<String, dynamic>?)?['professional_profiles']
                as Map<String, dynamic>?)
            ?['specialty']
            as String?,
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    professionalId,
    scheduledAt,
    durationMinutes,
    status,
    reason,
    notes,
    meetingUrl,
    patientFeedback,
    professionalNotes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
    patientPhone,
    professionalName,
    professionalSpecialty,
  ];
}
