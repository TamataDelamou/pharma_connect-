import 'package:equatable/equatable.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-5 / RG-REG-02 : modèle
// léger correspondant à la vue Postgres `adverse_reactions_anonymized`
// (créée en Étape 2), qui ne contient aucune colonne nominative de patient
// ou de déclarant. C'est la SEULE source de données que l'écran doit
// utiliser pour un compte de rôle 'regulateur' — jamais `AdverseReaction`
// (modèle de la table brute) ni `RegulatorService.getAdverseReactions()`.
class AdverseReactionAnonymized extends Equatable {
  final String id;
  final String? medicationId;
  final String? medicationGenericName;
  final String severity; // mild, moderate, severe, life_threatening
  final String status; // pending, under_review, investigating, closed, rejected
  final DateTime reactionDate;
  final String? outcome;
  final String reporterType;
  final DateTime createdAt;

  const AdverseReactionAnonymized({
    required this.id,
    this.medicationId,
    this.medicationGenericName,
    required this.severity,
    required this.status,
    required this.reactionDate,
    this.outcome,
    required this.reporterType,
    required this.createdAt,
  });

  factory AdverseReactionAnonymized.fromJson(Map<String, dynamic> json) =>
      AdverseReactionAnonymized(
        id: json['id'] as String,
        medicationId: json['medication_id'] as String?,
        medicationGenericName: json['medication_generic_name'] as String?,
        severity: json['severity'] as String,
        status: json['status'] as String,
        reactionDate: DateTime.parse(json['reaction_date'] as String),
        outcome: json['outcome'] as String?,
        reporterType: json['reporter_type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [
    id,
    medicationId,
    medicationGenericName,
    severity,
    status,
    reactionDate,
    outcome,
    reporterType,
    createdAt,
  ];

  String get severityLabel {
    switch (severity) {
      case 'mild':
        return 'Léger';
      case 'moderate':
        return 'Modéré';
      case 'severe':
        return 'Sévère';
      case 'life_threatening':
        return 'Engage le pronostic vital';
      default:
        return severity;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'under_review':
        return 'En cours d\'examen';
      case 'investigating':
        return 'En investigation';
      case 'closed':
        return 'Clos';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }
}
