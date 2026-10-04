import '../../../core/theme/palette.dart';

enum RecallStatus { draft, inProgress, completed, cancelled }

extension RecallStatusExtension on RecallStatus {
  String get label {
    switch (this) {
      case RecallStatus.draft:
        return 'Brouillon';
      case RecallStatus.inProgress:
        return 'En cours';
      case RecallStatus.completed:
        return 'Terminé';
      case RecallStatus.cancelled:
        return 'Annulé';
    }
  }

  ColorRole get color {
    switch (this) {
      case RecallStatus.draft:
        return ColorRole.textMuted;
      case RecallStatus.inProgress:
        return ColorRole.warning;
      case RecallStatus.completed:
        return ColorRole.success;
      case RecallStatus.cancelled:
        return ColorRole.danger;
    }
  }
}
