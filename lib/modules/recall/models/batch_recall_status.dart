enum BatchRecallStatus { pending, inProgress, completed, partial, cancelled }

extension BatchRecallStatusExtension on BatchRecallStatus {
  String get label {
    switch (this) {
      case BatchRecallStatus.pending:
        return 'En attente';
      case BatchRecallStatus.inProgress:
        return 'En cours';
      case BatchRecallStatus.completed:
        return 'Terminé';
      case BatchRecallStatus.partial:
        return 'Partiel';
      case BatchRecallStatus.cancelled:
        return 'Annulé';
    }
  }
}
