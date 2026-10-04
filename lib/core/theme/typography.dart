import 'package:flutter/material.dart';

/// Tailles, graisses et interlignes. Les styles ne portent pas de couleur
/// (C234) : elle vient du thème, par `context.text` (palette.dart) ou, à
/// défaut, par la couleur de texte par défaut du thème.
class PharmaConnectTypography {
  static const String fontFamily = 'Inter';

  // ==================== TEXT STYLES ====================
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.3,
  );

  /// Petit texte d'accompagnement (mention, légende), en police normale.
  static const TextStyle micro = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Police à chasse fixe, réservée aux codes, aux montants et aux
  /// références (C234).
  static const TextStyle mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle kpiLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  static const TextStyle kpiMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  static const TextStyle kpiSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  // ==================== ÉCHELLE ADAPTATIVE (C233) ====================
  // Les styles ci-dessus sont des constantes, utilisées telles quelles dans
  // tous les écrans. L'adaptation aux petits écrans se fait donc ici, par
  // une échelle de texte appliquée une seule fois à la racine de
  // l'application (AdaptiveTextScale), et non écran par écran.

  /// En dessous de cette largeur (téléphone), les grandes tailles sont
  /// réduites.
  static const double compactBreakpoint = 600;

  /// Réglage de taille de texte du téléphone (accessibilité) : respecté,
  /// plafonné pour que la mise en page tienne.
  static const double maxSystemTextScale = 1.3;

  /// Taille effective en largeur téléphone. Le texte courant (≤ 16 px) ne
  /// change pas : body1 reste à 16, body2 à 14. Les titres perdent 20 à 30 % :
  /// heading3 22 → 18, heading2 28 → 21, heading1 36 → 26, kpiMedium 32 →
  /// 23,5, kpiLarge 48 → 34. Interpolation linéaire entre ces repères, pour
  /// que les tailles codées en dur (18, 20, 24…) suivent la même règle.
  static double compactFontSize(double size) {
    const stops = [
      (16.0, 16.0),
      (22.0, 18.0),
      (28.0, 21.0),
      (36.0, 26.0),
      (48.0, 34.0),
    ];
    if (size <= stops.first.$1) return size;
    for (var i = 1; i < stops.length; i++) {
      final (x0, y0) = stops[i - 1];
      final (x1, y1) = stops[i];
      if (size <= x1) return y0 + (size - x0) * (y1 - y0) / (x1 - x0);
    }
    return size * stops.last.$2 / stops.last.$1;
  }

  /// Échelle de texte pour une largeur d'écran et le réglage du téléphone.
  static TextScaler textScalerFor({
    required double width,
    required TextScaler system,
  }) => AdaptiveTextScaler(
    compact: width < compactBreakpoint,
    system: system.clamp(maxScaleFactor: maxSystemTextScale),
  );
}

/// C233 : échelle de texte qui réduit les grandes tailles en largeur
/// téléphone ([PharmaConnectTypography.compactFontSize]), puis applique le
/// réglage de taille de texte du téléphone, déjà plafonné.
class AdaptiveTextScaler extends TextScaler {
  final bool compact;
  final TextScaler system;

  const AdaptiveTextScaler({required this.compact, required this.system});

  @override
  double scale(double fontSize) => system.scale(
    compact ? PharmaConnectTypography.compactFontSize(fontSize) : fontSize,
  );

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => system.textScaleFactor;

  @override
  bool operator ==(Object other) =>
      other is AdaptiveTextScaler &&
      other.compact == compact &&
      other.system == system;

  @override
  int get hashCode => Object.hash(compact, system);
}
