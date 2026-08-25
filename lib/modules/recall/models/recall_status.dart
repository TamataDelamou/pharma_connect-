import 'package:flutter/material.dart';

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
        return Colors.grey;
      case RecallStatus.inProgress:
        return Colors.orange;
      case RecallStatus.completed:
        return Colors.green;
      case RecallStatus.cancelled:
        return Colors.red;
    }
  }
}
