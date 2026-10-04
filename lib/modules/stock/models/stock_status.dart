import '../../../core/theme/palette.dart';

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

  ColorRole get color {
    switch (this) {
      case StockStatus.inStock:
        return ColorRole.success;
      case StockStatus.lowStock:
        return ColorRole.warning;
      case StockStatus.critical:
        return ColorRole.warningStrong;
      case StockStatus.outOfStock:
        return ColorRole.danger;
      case StockStatus.discontinued:
        return ColorRole.textMuted;
    }
  }
}
