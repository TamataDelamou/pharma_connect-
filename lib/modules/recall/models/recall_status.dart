import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

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

  Color get color {
    switch (this) {
      case RecallStatus.draft:
        return PharmaConnectColors.neutralMuted;
      case RecallStatus.inProgress:
        return PharmaConnectColors.accentOrange;
      case RecallStatus.completed:
        return PharmaConnectColors.accentGreen;
      case RecallStatus.cancelled:
        return PharmaConnectColors.accentRed;
    }
  }
}
