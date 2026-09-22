enum TriageStatus { waiting, inAssessment, assigned, discharged, transferred }

extension TriageStatusExtension on TriageStatus {
  String get label {
    switch (this) {
      case TriageStatus.waiting:
        return 'En attente';
      case TriageStatus.inAssessment:
        return 'En évaluation';
      case TriageStatus.assigned:
        return 'Assigné';
      case TriageStatus.discharged:
        return 'Sorti';
      case TriageStatus.transferred:
        return 'Transféré';
    }
  }

  String get icon {
    switch (this) {
      case TriageStatus.waiting:
        return '⏳';
      case TriageStatus.inAssessment:
        return '🩺';
      case TriageStatus.assigned:
        return '✅';
      case TriageStatus.discharged:
        return '🏠';
      case TriageStatus.transferred:
        return '🚑';
    }
  }

  bool get isActive =>
      this == TriageStatus.waiting || this == TriageStatus.inAssessment;
  bool get isCompleted =>
      this == TriageStatus.discharged || this == TriageStatus.transferred;
}
