import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'spacing.dart';

/// C234 : les deux thèmes sont construits par la même fonction, à partir du
/// contrat de couleurs par rôle ([PharmaConnectPalette]). Thème par défaut :
/// clair ; le thème sombre est conservé à l'identique.
class PharmaConnectAppTheme {
  static ThemeData light() => _build(PharmaConnectPalette.light);

  static ThemeData dark() => _build(PharmaConnectPalette.dark);

  static ThemeData _build(PharmaConnectPalette p) {
    final text = PharmaConnectTextStyles(p);
    // Les réglages « isDark ? null : … » ne valent que pour le thème clair :
    // en sombre, les valeurs par défaut de Material restent celles d'avant
    // C234.
    final isDark = p.isDark;

    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      extensions: [p],

      // ==================== COULEURS ====================
      primaryColor: p.primary,
      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: p.primary,
        onPrimary: p.onPrimary,
        secondary: p.secondary,
        onSecondary: isDark ? p.textPrimary : p.onPrimary,
        // En sombre, la surface du contrat est un voile translucide : le
        // ColorScheme garde le fond opaque d'origine.
        surface: isDark ? p.background : p.surface,
        onSurface: p.textPrimary,
        onSurfaceVariant: isDark ? null : p.textSecondary,
        error: p.danger,
        onError: p.onDanger,
        outline: isDark ? null : p.border,
        outlineVariant: isDark ? null : p.border,
        shadow: isDark ? null : p.shadow,
        scrim: isDark ? null : p.overlay,
        // Pas de teinte Material 3 sur les surfaces surélevées, en clair.
        surfaceTint: isDark ? null : Colors.transparent,
      ),

      // ==================== TYPOGRAPHIE ====================
      textTheme: text.textTheme,
      iconTheme: isDark ? null : IconThemeData(color: p.textPrimary),
      dividerTheme: isDark
          ? null
          : DividerThemeData(color: p.border, thickness: 1, space: 1),

      // ==================== SCAFFOLD ====================
      scaffoldBackgroundColor: p.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: isDark ? null : 0,
        titleTextStyle: text.heading2,
        iconTheme: IconThemeData(color: p.textPrimary),
        actionsIconTheme: IconThemeData(color: p.textPrimary),
        // Barre de statut du thème clair : icônes sombres.
        systemOverlayStyle: isDark
            ? null
            : SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: p.background,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
      ),

      // ==================== CARDS ====================
      cardTheme: CardThemeData(
        color: isDark ? Colors.transparent : p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
          side: isDark ? BorderSide.none : BorderSide(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ==================== INPUTS ====================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        border: inputBorder(p.border, 1),
        enabledBorder: inputBorder(p.border, 1),
        focusedBorder: inputBorder(p.primary, 2),
        errorBorder: inputBorder(p.danger, 2),
        focusedErrorBorder: inputBorder(p.danger, 2),
        labelStyle: text.label,
        hintStyle: text.body2.copyWith(color: p.textHint),
        errorStyle: isDark ? null : text.body2.copyWith(color: p.danger),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
      ),
      textSelectionTheme: isDark
          ? null
          : TextSelectionThemeData(
              cursorColor: p.primary,
              selectionColor: p.primary.withValues(alpha: 0.25),
              selectionHandleColor: p.primary,
            ),

      // ==================== BOUTONS ====================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: isDark
          ? null
          : OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: p.primary,
                side: BorderSide(color: p.border),
              ),
            ),

      // Puces de choix : texte lisible dans les deux états, en clair.
      chipTheme: isDark
          ? null
          : ChipThemeData(
              backgroundColor: p.surface,
              selectedColor: p.primary.withValues(alpha: 0.12),
              checkmarkColor: p.primary,
              labelStyle: text.body2.copyWith(color: p.textPrimary),
              secondaryLabelStyle: text.body2.copyWith(
                color: p.primary,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: p.border),
            ),

      // ==================== DIALOGS ====================
      dialogTheme: DialogThemeData(
        // En sombre, les dialogues de l'application posent leur propre fond
        // (verre) ; en clair, fond blanc.
        backgroundColor: isDark ? Colors.transparent : p.surface,
        elevation: 0,
        titleTextStyle: isDark ? null : text.heading3,
        contentTextStyle: isDark ? null : text.body2,
        barrierColor: isDark ? null : p.overlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusXl),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      bottomSheetTheme: isDark
          ? null
          : BottomSheetThemeData(
              backgroundColor: p.surface,
              modalBarrierColor: p.overlay,
            ),
      snackBarTheme: isDark
          ? null
          : SnackBarThemeData(
              backgroundColor: p.textPrimary,
              contentTextStyle: text.body2.copyWith(color: p.background),
            ),

      // ==================== FONTES ====================
      fontFamily: 'Inter',
    );
  }
}
