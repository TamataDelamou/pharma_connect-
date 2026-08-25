import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class PharmaConnectAppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ==================== COULEURS ====================
      primaryColor: PharmaConnectColors.accentCyan,
      colorScheme: const ColorScheme.dark(
        primary: PharmaConnectColors.accentCyan,
        secondary: PharmaConnectColors.accentPurple,
        surface: PharmaConnectColors.primaryDeep,
        error: PharmaConnectColors.accentRed,
        onPrimary: PharmaConnectColors.textOnAccent,
        onSecondary: PharmaConnectColors.textPrimary,
        onSurface: PharmaConnectColors.textPrimary,
        onError: PharmaConnectColors.textPrimary,
      ),

      // ==================== TYPOGRAPHIE ====================
      textTheme: PharmaConnectTypography.textTheme,

      // ==================== SCAFFOLD ====================
      scaffoldBackgroundColor: PharmaConnectColors.primaryDeep,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: PharmaConnectTypography.heading2,
        iconTheme: IconThemeData(color: PharmaConnectColors.textPrimary),
        actionsIconTheme: IconThemeData(color: PharmaConnectColors.textPrimary),
      ),

      // ==================== CARDS ====================
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ==================== INPUTS ====================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: const BorderSide(
            color: PharmaConnectColors.accentCyan,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: const BorderSide(
            color: PharmaConnectColors.accentRed,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: const BorderSide(
            color: PharmaConnectColors.accentRed,
            width: 2,
          ),
        ),
        labelStyle: PharmaConnectTypography.label,
        hintStyle: PharmaConnectTypography.body2.copyWith(
          color: PharmaConnectColors.textSecondary.withValues(alpha: 0.5),
        ),
        prefixIconColor: PharmaConnectColors.textSecondary,
        suffixIconColor: PharmaConnectColors.textSecondary,
      ),

      // ==================== BOUTONS ====================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PharmaConnectColors.accentCyan,
          foregroundColor: PharmaConnectColors.textOnAccent,
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

      // ==================== DIALOGS ====================
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusXl),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ==================== FONTES ====================
      fontFamily: 'Inter',
    );
  }

  // ==================== THÈME CLAIR (OPTIONNEL) ====================
  static ThemeData light() {
    // À développer ultérieurement
    return dark();
  }
}
