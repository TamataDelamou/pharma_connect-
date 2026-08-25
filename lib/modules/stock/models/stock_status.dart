import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart'; // <-- Ajout

enum StockStatus {
  inStock, // En stock
  lowStock, // Stock faible (seuil bas)
  critical, // Stock critique (seuil critique)
  outOfStock, // Rupture
  discontinued, // Arrêté
}

extension StockStatusExtension on StockStatus {
  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'En stock';
      case StockStatus.lowStock:
        return 'Stock faible';
      case StockStatus.critical:
        return 'Stock critique';
      case StockStatus.outOfStock:
        return 'Rupture';
      case StockStatus.discontinued:
        return 'Arrêté';
    }
  }

  Color get color {
    switch (this) {
      case StockStatus.inStock:
        return PharmaConnectColors.accentGreen;
      case StockStatus.lowStock:
        return PharmaConnectColors.accentOrange;
      case StockStatus.critical:
        return PharmaConnectColors.accentAmber;
      case StockStatus.outOfStock:
        return PharmaConnectColors.accentRed;
      case StockStatus.discontinued:
        return PharmaConnectColors.neutralMuted;
    }
  }
}
