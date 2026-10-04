import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart'; // <-- Ajout
import '../../../core/theme/palette.dart';

enum BatchStatus {
  manufactured,
  inTransit,
  atDistributor,
  atPharmacy,
  sold,
  dispensed,
  returned,
  recalled,
  destroyed,
}

extension BatchStatusExtension on BatchStatus {
  String get label {
    switch (this) {
      case BatchStatus.manufactured:
        return 'Fabriqué';
      case BatchStatus.inTransit:
        return 'En transit';
      case BatchStatus.atDistributor:
        return 'Chez le grossiste';
      case BatchStatus.atPharmacy:
        return 'En pharmacie';
      case BatchStatus.sold:
        return 'Vendu';
      case BatchStatus.dispensed:
        return 'Dispensé';
      case BatchStatus.returned:
        return 'Retourné';
      case BatchStatus.recalled:
        return 'Rappelé';
      case BatchStatus.destroyed:
        return 'Détruit';
    }
  }

  String get icon {
    switch (this) {
      case BatchStatus.manufactured:
        return '🏭';
      case BatchStatus.inTransit:
        return '🚚';
      case BatchStatus.atDistributor:
        return '📦';
      case BatchStatus.atPharmacy:
        return '🏪';
      case BatchStatus.sold:
        return '🛒';
      case BatchStatus.dispensed:
        return '💊';
      case BatchStatus.returned:
        return '↩️';
      case BatchStatus.recalled:
        return '🔴';
      case BatchStatus.destroyed:
        return '💀';
    }
  }

  ColorRole get color {
    switch (this) {
      case BatchStatus.manufactured:
        return ColorRole.secondary;
      case BatchStatus.inTransit:
        return ColorRole.primary;
      case BatchStatus.atDistributor:
        return ColorRole.success;
      case BatchStatus.atPharmacy:
        return ColorRole.warning;
      case BatchStatus.sold:
        return ColorRole.textMuted;
      case BatchStatus.dispensed:
        return ColorRole.success;
      case BatchStatus.returned:
        return ColorRole.textSecondary;
      case BatchStatus.recalled:
        return ColorRole.danger;
      case BatchStatus.destroyed:
        return ColorRole.textMuted;
    }
  }
}
