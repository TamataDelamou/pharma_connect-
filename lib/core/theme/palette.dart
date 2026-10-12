import 'package:flutter/material.dart';

import 'spacing.dart';
import 'typography.dart';

/// C234 : contrat de couleurs par rôle (KER-DES-03, noms en anglais
/// KER-NOM-03). Les écrans et les widgets lisent un rôle
/// (`context.palette.textPrimary`), jamais une valeur : le thème clair et le
/// thème sombre sont deux instances de ce même contrat.
@immutable
class PharmaConnectPalette extends ThemeExtension<PharmaConnectPalette> {
  final Brightness brightness;

  // ==================== FONDS ====================
  /// Fond de page.
  final Color background;

  /// Fond des cartes, des champs de saisie et des feuilles.
  final Color surface;

  /// Fond discret : zone secondaire, élément désactivé, ligne survolée.
  final Color surfaceMuted;

  /// Fond d'un élément mis en avant ou sélectionné.
  final Color surfaceRaised;

  final Color border;

  // ==================== TEXTE ====================
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // ==================== MARQUE ====================
  final Color primary;

  /// Texte et icônes posés sur [primary].
  final Color onPrimary;
  final Color secondary;

  // ==================== ÉTATS ====================
  final Color success;
  final Color warning;

  /// Alerte plus appuyée que [warning], avant [danger].
  final Color warningStrong;
  final Color danger;

  /// Texte et icônes posés sur [danger].
  final Color onDanger;
  final Color info;

  // ==================== VOILES ET OMBRES ====================
  /// Voile derrière une fenêtre modale.
  final Color overlay;
  final Color shadow;

  // ==================== CARTES ====================
  // Remplacent PharmaConnectGlass : verre translucide en sombre, carte
  // blanche bordée avec une ombre légère en clair.
  final BoxDecoration card;
  final BoxDecoration cardRaised;
  final BoxDecoration cardSubtle;

  const PharmaConnectPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.warningStrong,
    required this.danger,
    required this.onDanger,
    required this.info,
    required this.overlay,
    required this.shadow,
    required this.card,
    required this.cardRaised,
    required this.cardSubtle,
  });

  bool get isDark => brightness == Brightness.dark;

  // ==================== THÈME SOMBRE ====================
  // Valeurs d'origine du produit, à l'identique.
  static final PharmaConnectPalette dark = PharmaConnectPalette(
    brightness: Brightness.dark,
    background: const Color(0xFF0A0E1A),
    surface: Colors.white.withValues(alpha: 0.06),
    surfaceMuted: Colors.white.withValues(alpha: 0.04),
    surfaceRaised: Colors.white.withValues(alpha: 0.12),
    border: Colors.white.withValues(alpha: 0.10),
    textPrimary: const Color(0xFFF5F7FA),
    textSecondary: const Color(0xFF9CA3AF),
    textMuted: const Color(0xFF6B7280),
    primary: const Color(0xFF00D9FF),
    onPrimary: const Color(0xFF0A0E1A),
    secondary: const Color(0xFF8B5CF6),
    success: const Color(0xFF10B981),
    warning: const Color(0xFFF59E0B),
    warningStrong: const Color(0xFFFF9100),
    danger: const Color(0xFFEF4444),
    onDanger: const Color(0xFFF5F7FA),
    info: const Color(0xFF00D9FF),
    overlay: const Color(0xB3000000),
    shadow: Colors.black.withValues(alpha: 0.35),
    card: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    cardRaised: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    cardSubtle: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.20),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
  );

  // ==================== THÈME CLAIR ====================
  // Blanc cassé. Chaque couleur de texte ou d'état atteint 4,5:1 sur
  // background et sur surface. Deux valeurs s'écartent de la demande C234
  // pour cette raison : textMuted (#8A909C → #636B78, 2,94:1 → 4,94:1) et
  // danger (#DC2626 → #C81E1E, 4,43:1 → 5,27:1 sur background).
  static final PharmaConnectPalette light = PharmaConnectPalette(
    brightness: Brightness.light,
    background: const Color(0xFFF7F5F0),
    surface: const Color(0xFFFFFFFF),
    surfaceMuted: const Color(0xFFEFECE5),
    surfaceRaised: const Color(0xFFFFFFFF),
    border: const Color(0xFFE3DFD6),
    textPrimary: const Color(0xFF1A1F2B),
    textSecondary: const Color(0xFF5B6270),
    textMuted: const Color(0xFF636B78),
    primary: const Color(0xFF0E7490),
    onPrimary: const Color(0xFFFFFFFF),
    secondary: const Color(0xFF7C3AED),
    success: const Color(0xFF047857),
    warning: const Color(0xFFB45309),
    warningStrong: const Color(0xFFC2410C),
    danger: const Color(0xFFC81E1E),
    onDanger: const Color(0xFFFFFFFF),
    info: const Color(0xFF0369A1),
    overlay: const Color(0x66000000),
    shadow: Colors.black.withValues(alpha: 0.06),
    card: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
      border: Border.all(color: const Color(0xFFE3DFD6), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    cardRaised: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
      border: Border.all(color: const Color(0xFFE3DFD6), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    cardSubtle: BoxDecoration(
      color: const Color(0xFFEFECE5),
      borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
      border: Border.all(color: const Color(0xFFE3DFD6), width: 1),
    ),
  );

  /// Texte d'exemple d'un champ de saisie vide.
  Color get textHint => textFaded(0.5);

  /// Texte d'arrière-plan (mention, pied de carte). En sombre,
  /// textSecondary atténué à [darkAlpha] ; en clair, textMuted, qui garde un
  /// contraste de 4,5:1.
  Color textFaded(double darkAlpha) =>
      isDark ? textSecondary.withValues(alpha: darkAlpha) : textMuted;

  /// Bordure plus discrète que [border] (carte secondaire, tuile).
  Color get borderSubtle =>
      isDark ? Colors.white.withValues(alpha: 0.06) : border;

  /// Fond d'un champ ou d'un élément désactivé.
  Color get surfaceDisabled =>
      isDark ? Colors.white.withValues(alpha: 0.03) : surfaceMuted;

  /// Voile de contraste posé sur le fond : séparateur, fond à peine marqué,
  /// icône d'illustration. Blanc translucide en sombre, encre translucide en
  /// clair. À ne pas utiliser pour du texte.
  Color veil(double alpha) => isDark
      ? Colors.white.withValues(alpha: alpha)
      : textPrimary.withValues(alpha: alpha * 0.6);

  /// Carte mise en avant par une couleur d'accent (bordure et halo).
  BoxDecoration cardGlow(Color accent) => card.copyWith(
    border: Border.all(
      color: accent.withValues(alpha: isDark ? 0.30 : 0.45),
      width: 1.5,
    ),
    boxShadow: [
      ...?card.boxShadow,
      BoxShadow(
        color: accent.withValues(alpha: isDark ? 0.20 : 0.10),
        blurRadius: isDark ? 24 : 16,
        spreadRadius: 0,
      ),
    ],
  );

  /// Fond teinté d'une couleur d'état (badge, bandeau, pastille).
  Color tint(Color color, [double alpha = 0.15]) =>
      color.withValues(alpha: isDark ? alpha : alpha * 0.8);

  @override
  PharmaConnectPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceRaised,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? success,
    Color? warning,
    Color? warningStrong,
    Color? danger,
    Color? onDanger,
    Color? info,
    Color? overlay,
    Color? shadow,
    BoxDecoration? card,
    BoxDecoration? cardRaised,
    BoxDecoration? cardSubtle,
  }) => PharmaConnectPalette(
    brightness: brightness ?? this.brightness,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    border: border ?? this.border,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    secondary: secondary ?? this.secondary,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    warningStrong: warningStrong ?? this.warningStrong,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    info: info ?? this.info,
    overlay: overlay ?? this.overlay,
    shadow: shadow ?? this.shadow,
    card: card ?? this.card,
    cardRaised: cardRaised ?? this.cardRaised,
    cardSubtle: cardSubtle ?? this.cardSubtle,
  );

  @override
  PharmaConnectPalette lerp(
    covariant ThemeExtension<PharmaConnectPalette>? other,
    double t,
  ) {
    if (other is! PharmaConnectPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return PharmaConnectPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      border: c(border, other.border),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      secondary: c(secondary, other.secondary),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      warningStrong: c(warningStrong, other.warningStrong),
      danger: c(danger, other.danger),
      onDanger: c(onDanger, other.onDanger),
      info: c(info, other.info),
      overlay: c(overlay, other.overlay),
      shadow: c(shadow, other.shadow),
      card: BoxDecoration.lerp(card, other.card, t)!,
      cardRaised: BoxDecoration.lerp(cardRaised, other.cardRaised, t)!,
      cardSubtle: BoxDecoration.lerp(cardSubtle, other.cardSubtle, t)!,
    );
  }
}

/// Styles de texte de [PharmaConnectTypography] avec la couleur du thème :
/// textPrimary pour les titres et le texte courant, textSecondary pour les
/// textes d'accompagnement.
class PharmaConnectTextStyles {
  final PharmaConnectPalette _palette;

  const PharmaConnectTextStyles(this._palette);

  TextStyle _primary(TextStyle style) =>
      style.copyWith(color: _palette.textPrimary);
  TextStyle _secondary(TextStyle style) =>
      style.copyWith(color: _palette.textSecondary);

  TextStyle get heading1 => _primary(PharmaConnectTypography.heading1);
  TextStyle get heading2 => _primary(PharmaConnectTypography.heading2);
  TextStyle get heading3 => _primary(PharmaConnectTypography.heading3);
  TextStyle get subtitle1 => _primary(PharmaConnectTypography.subtitle1);
  TextStyle get subtitle2 => _secondary(PharmaConnectTypography.subtitle2);
  TextStyle get body1 => _primary(PharmaConnectTypography.body1);
  TextStyle get body2 => _secondary(PharmaConnectTypography.body2);
  TextStyle get label => _secondary(PharmaConnectTypography.label);
  TextStyle get micro => _secondary(PharmaConnectTypography.micro);
  TextStyle get mono => _secondary(PharmaConnectTypography.mono);
  TextStyle get kpiLarge => _primary(PharmaConnectTypography.kpiLarge);
  TextStyle get kpiMedium => _primary(PharmaConnectTypography.kpiMedium);
  TextStyle get kpiSmall => _primary(PharmaConnectTypography.kpiSmall);

  TextTheme get textTheme => TextTheme(
    displayLarge: heading1,
    displayMedium: heading2,
    displaySmall: heading3,
    headlineMedium: subtitle1,
    headlineSmall: subtitle2,
    bodyLarge: body1,
    // Couleur par défaut de tout texte sans couleur propre (DefaultTextStyle
    // de Material) : textPrimary, pour que les styles de
    // PharmaConnectTypography, sans couleur, suivent le thème.
    bodyMedium: _primary(PharmaConnectTypography.body2),
    labelLarge: label,
    labelSmall: micro,
  );
}

extension PharmaConnectThemeContext on BuildContext {
  /// Couleurs par rôle du thème courant.
  PharmaConnectPalette get palette =>
      Theme.of(this).extension<PharmaConnectPalette>() ??
      PharmaConnectPalette.light;

  /// Styles de texte avec la couleur du thème courant.
  PharmaConnectTextStyles get text => PharmaConnectTextStyles(palette);
}

/// Rôle de couleur pour le code qui n'a pas de `BuildContext` (modèles,
/// énumérations, services) : il nomme le rôle, l'écran le traduit en couleur
/// du thème courant par `role.of(context.palette)`.
enum ColorRole {
  background,
  surface,
  surfaceMuted,
  surfaceRaised,
  border,
  textPrimary,
  textSecondary,
  textMuted,
  primary,
  onPrimary,
  secondary,
  success,
  warning,
  warningStrong,
  danger,
  onDanger,
  info,
  overlay,
  shadow;

  Color of(PharmaConnectPalette p) => switch (this) {
    ColorRole.background => p.background,
    ColorRole.surface => p.surface,
    ColorRole.surfaceMuted => p.surfaceMuted,
    ColorRole.surfaceRaised => p.surfaceRaised,
    ColorRole.border => p.border,
    ColorRole.textPrimary => p.textPrimary,
    ColorRole.textSecondary => p.textSecondary,
    ColorRole.textMuted => p.textMuted,
    ColorRole.primary => p.primary,
    ColorRole.onPrimary => p.onPrimary,
    ColorRole.secondary => p.secondary,
    ColorRole.success => p.success,
    ColorRole.warning => p.warning,
    ColorRole.warningStrong => p.warningStrong,
    ColorRole.danger => p.danger,
    ColorRole.onDanger => p.onDanger,
    ColorRole.info => p.info,
    ColorRole.overlay => p.overlay,
    ColorRole.shadow => p.shadow,
  };
}

/// Couleurs qui ne dépendent pas du thème : couleur de marque d'un tiers et
/// couleurs conventionnelles (métaux des paliers de fidélité). Tout le reste
/// passe par un rôle de [PharmaConnectPalette].
class PharmaConnectFixedColors {
  static const Color whatsapp = Color(0xFF25D366);
  static const Color onWhatsapp = Color(0xFFFFFFFF);

  /// Texte posé sur l'image de la caméra (lecteur de code-barres) : clair
  /// dans les deux thèmes.
  static const Color cameraBackdrop = Color(0xFF000000);
  static const Color onCamera = Color(0xFFFFFFFF);
  static const Color onCameraMuted = Color(0xB3FFFFFF);

  /// C256 : QR code. Modules noirs sur fond blanc dans les deux thèmes, le
  /// contraste dont un lecteur a besoin.
  static const Color qrBackground = Color(0xFFFFFFFF);
  static const Color qrModule = Color(0xFF000000);

  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierGold = Color(0xFFFFD700);
  static const Color tierPlatinum = Color(0xFFE5E4E2);

  /// Texte posé sur une pastille de palier : foncé, 4,5:1 au moins sur les
  /// quatre métaux. Un métal ne sert jamais de couleur de texte.
  static const Color onTier = Color(0xFF1A1F2B);
}
