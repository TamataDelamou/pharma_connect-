enum FamilyAlertType {
  healthRecord,
  prescription,
  consultation,
  medicationRefill,
  general,
}

extension FamilyAlertTypeExtension on FamilyAlertType {
  String get label {
    switch (this) {
      case FamilyAlertType.healthRecord:
        return 'Dossier de santé';
      case FamilyAlertType.prescription:
        return 'Ordonnance';
      case FamilyAlertType.consultation:
        return 'Consultation';
      case FamilyAlertType.medicationRefill:
        return 'Renouvellement';
      case FamilyAlertType.general:
        return 'Information';
    }
  }

  String get icon {
    switch (this) {
      case FamilyAlertType.healthRecord:
        return '📋';
      case FamilyAlertType.prescription:
        return '💊';
      case FamilyAlertType.consultation:
        return '🩺';
      case FamilyAlertType.medicationRefill:
        return '🔄';
      case FamilyAlertType.general:
        return '📢';
    }
  }
}
