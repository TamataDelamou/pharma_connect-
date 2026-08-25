import 'package:flutter/material.dart';

import 'colors.dart';

class PharmaConnectTypography {
  static const String fontFamily = 'Inter';

  // ==================== TEXT STYLES ====================
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: PharmaConnectColors.textSecondary,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: PharmaConnectColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: PharmaConnectColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: 'JetBrainsMono', // Police monospace pour code
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: PharmaConnectColors.textSecondary,
  );

  static const TextStyle kpiLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle kpiMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle kpiSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: PharmaConnectColors.textPrimary,
  );

  // ==================== TEXT THEME ====================
  static TextTheme get textTheme => const TextTheme(
    displayLarge: heading1,
    displayMedium: heading2,
    displaySmall: heading3,
    headlineMedium: subtitle1,
    headlineSmall: subtitle2,
    bodyLarge: body1,
    bodyMedium: body2,
    labelLarge: label,
    labelSmall: micro,
  );
}
