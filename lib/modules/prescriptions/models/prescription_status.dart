enum PrescriptionStatus { draft, pending, validated, dispensed, archived }

extension PrescriptionStatusExtension on PrescriptionStatus {
  String get label {
    switch (this) {
      case PrescriptionStatus.draft:
        return 'Brouillon';
      case PrescriptionStatus.pending:
        return 'En attente';
      case PrescriptionStatus.validated:
        return 'Validée';
      case PrescriptionStatus.dispensed:
        return 'Dispensée';
      case PrescriptionStatus.archived:
        return 'Archivée';
    }
  }

  String get icon {
    switch (this) {
      case PrescriptionStatus.draft:
        return '📄';
      case PrescriptionStatus.pending:
        return '⏳';
      case PrescriptionStatus.validated:
        return '✅';
      case PrescriptionStatus.dispensed:
        return '💊';
      case PrescriptionStatus.archived:
        return '📁';
    }
  }
}
