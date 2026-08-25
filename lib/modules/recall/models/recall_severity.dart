enum RecallSeverity {
  classI, // Danger de mort ou risque grave
  classII, // Effet indésirable réversible
  classIII, // Non-conformité mineure
}

extension RecallSeverityExtension on RecallSeverity {
  String get label {
    switch (this) {
      case RecallSeverity.classI:
        return 'Classe I - Urgent';
      case RecallSeverity.classII:
        return 'Classe II - Moyen';
      case RecallSeverity.classIII:
        return 'Classe III - Faible';
    }
  }

  String get description {
    switch (this) {
      case RecallSeverity.classI:
        return 'Danger de mort ou risque grave pour la santé';
      case RecallSeverity.classII:
        return 'Effet indésirable réversible ou risque modéré';
      case RecallSeverity.classIII:
        return 'Non-conformité mineure ou risque faible';
    }
  }
}
