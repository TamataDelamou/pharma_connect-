import 'package:equatable/equatable.dart';

// Audit Module 17 (TRI, 30/08/2026), correctif de compilation (bug 1) :
// `TriageAIService`/`TriageAIProvider` importaient déjà `../models/triage_rules.dart`
// et utilisaient la classe `TriageRule` (fromJson/copyWith/toJson) dans une
// dizaine de sites — mais ce fichier n'existait nulle part dans le projet
// (`triage/models/` ne contenait que 4 fichiers : triage_ai_analysis.dart,
// triage_assessment.dart, triage_patient.dart, triage_status.dart). Erreur de
// compilation bloquante pour tout le module (et donc pour l'application
// entière dès l'inclusion de ces fichiers) — reconstruit ici à partir de la
// table `public.triage_rules` (migration `20260828012000_triage_ai.sql`) et
// de l'usage réel observé dans `triage_ai_service.dart`/`triage_ai_provider.dart`.
class TriageRule extends Equatable {
  final String id;
  final String keyword;
  final int priorityScore;
  final String? department;
  final bool isCritical;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const TriageRule({
    required this.id,
    required this.keyword,
    required this.priorityScore,
    this.department,
    this.isCritical = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  TriageRule copyWith({
    String? id,
    String? keyword,
    int? priorityScore,
    String? department,
    bool? isCritical,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return TriageRule(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      priorityScore: priorityScore ?? this.priorityScore,
      department: department ?? this.department,
      isCritical: isCritical ?? this.isCritical,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'keyword': keyword,
    'priority_score': priorityScore,
    if (department != null) 'department': department,
    'is_critical': isCritical,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory TriageRule.fromJson(Map<String, dynamic> json) => TriageRule(
    id: json['id'] as String,
    keyword: json['keyword'] as String,
    priorityScore: json['priority_score'] as int,
    department: json['department'] as String?,
    isCritical: json['is_critical'] as bool? ?? false,
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
    keyword,
    priorityScore,
    department,
    isCritical,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];
}
