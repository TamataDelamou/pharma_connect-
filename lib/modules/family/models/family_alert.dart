import 'package:equatable/equatable.dart';
import 'family_alert_type.dart';

class FamilyAlert extends Equatable {
  final String id;
  final String familyLinkId;
  final FamilyAlertType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived fields
  final String? patientName;

  const FamilyAlert({
    required this.id,
    required this.familyLinkId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
  });

  FamilyAlert copyWith({
    String? id,
    String? familyLinkId,
    FamilyAlertType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
  }) {
    return FamilyAlert(
      id: id ?? this.id,
      familyLinkId: familyLinkId ?? this.familyLinkId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_link_id': familyLinkId,
    'type': type.name,
    'title': title,
    'message': message,
    'is_read': isRead,
    if (readAt != null) 'read_at': readAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory FamilyAlert.fromJson(Map<String, dynamic> json) => FamilyAlert(
    id: json['id'] as String,
    familyLinkId: json['family_link_id'] as String,
    type: FamilyAlertType.values.firstWhere(
      (e) => e.name == (json['type'] as String),
      orElse: () => FamilyAlertType.general,
    ),
    title: json['title'] as String,
    message: json['message'] as String,
    isRead: json['is_read'] as bool? ?? false,
    readAt: json['read_at'] != null
        ? DateTime.parse(json['read_at'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    // Audit Module 22 (FAM), Étape 3 (30/08/2026), FAM-5 : aligné sur la
    // forme JSON produite par le correctif de `FamilyService.getAlertsForUser()`
    // (`family_links!inner(patients:patient_id(full_name))`) — auparavant
    // `json['patients']['full_name']` cherchait `full_name` un niveau trop
    // haut (l'embed d'origine imbriquait `patients` → `patient_id` →
    // `full_name`), donc `patientName` valait toujours `null` en pratique
    // pour les appels passant par `getAlertsForUser()`.
    patientName: _patientNameFromJson(json),
  );

  // Phase 5 (module family) : même motif que consultation.dart (module
  // teleconsult, Phase 4) — un chaînage `?[...]` après un cast `as` produit
  // une erreur de parsing Dart (non_bool_condition / missing_identifier).
  // Ici la chaîne était en plus imbriquée dans le "then" d'un opérateur
  // ternaire, ce qui aggrave l'ambiguïté de la grammaire Dart. Extrait en
  // fonction dédiée avec des `if` explicites plutôt qu'un chaînage
  // imbriqué, pour lever l'ambiguïté définitivement plutôt que de
  // reproduire un chaînage tout aussi fragile.
  static String? _patientNameFromJson(Map<String, dynamic> json) {
    final familyLinks = json['family_links'] as Map<String, dynamic>?;
    if (familyLinks != null) {
      final patients = familyLinks['patients'] as Map<String, dynamic>?;
      return patients?['full_name'] as String?;
    }
    final patients = json['patients'] as Map<String, dynamic>?;
    return patients?['full_name'] as String?;
  }

  @override
  List<Object?> get props => [
    id,
    familyLinkId,
    type,
    title,
    message,
    isRead,
    readAt,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
  ];
}
