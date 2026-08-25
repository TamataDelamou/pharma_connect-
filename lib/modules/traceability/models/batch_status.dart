import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart'; // <-- Ajout

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

  Color get color {
    switch (this) {
      case BatchStatus.manufactured:
        return PharmaConnectColors.accentPurple;
      case BatchStatus.inTransit:
        return PharmaConnectColors.accentCyan;
      case BatchStatus.atDistributor:
        return PharmaConnectColors.accentGreen;
      case BatchStatus.atPharmacy:
        return PharmaConnectColors.accentOrange;
      case BatchStatus.sold:
        return PharmaConnectColors.neutralMuted;
      case BatchStatus.dispensed:
        return PharmaConnectColors.accentGreen;
      case BatchStatus.returned:
        return PharmaConnectColors.textSecondary;
      case BatchStatus.recalled:
        return PharmaConnectColors.accentRed;
      case BatchStatus.destroyed:
        return PharmaConnectColors.neutralDark;
    }
  }
}
