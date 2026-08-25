import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';

class PharmaConnectGlass {
  // ==================== GLASS STYLES ====================
  static BoxDecoration glassPrimary = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.10),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration glassDark = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.10),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration glassLight = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.04),
    borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.06),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration glassGlowCyan = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
    border: Border.all(
      color: PharmaConnectColors.accentCyan.withValues(alpha: 0.30),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: PharmaConnectColors.accentCyan.withValues(alpha: 0.20),
        blurRadius: 24,
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration glassGlowPurple = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
    border: Border.all(
      color: PharmaConnectColors.accentPurple.withValues(alpha: 0.30),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: PharmaConnectColors.accentPurple.withValues(alpha: 0.20),
        blurRadius: 24,
        spreadRadius: 0,
      ),
    ],
  );

  // ==================== GLASS UTILITY ====================
  static BoxDecoration glassCustom({
    required double opacity,
    double borderRadius = 16,
    Color borderColor = Colors.transparent,
    double borderWidth = 0,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != Colors.transparent
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow:
          shadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
    );
  }

  // ==================== GLASS MODAL OVERLAY ====================
  static BoxDecoration glassModalOverlay = const BoxDecoration(
    color: PharmaConnectColors.overlayDark,
    backgroundBlendMode: BlendMode.darken,
  );
}
