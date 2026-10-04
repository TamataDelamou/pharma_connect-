import 'package:flutter/material.dart';

import '../../theme/spacing.dart';
import '../../theme/palette.dart';

enum StatusBadgeType {
  success, // Vert
  warning, // Orange
  danger, // Rouge
  info, // Cyan
  kernel, // Violet
  neutral, // Gris
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType status;
  final bool showGlow;

  const StatusBadge({
    super.key,
    required this.label,
    required this.status,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = _getColor(palette);
    final glow = _getGlow(palette, color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: palette.tint(color),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: glow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(PharmaConnectPalette p) {
    switch (status) {
      case StatusBadgeType.success:
        return p.success;
      case StatusBadgeType.warning:
        return p.warning;
      case StatusBadgeType.danger:
        return p.danger;
      case StatusBadgeType.info:
        return p.info;
      case StatusBadgeType.kernel:
        return p.secondary;
      case StatusBadgeType.neutral:
        return p.textSecondary;
    }
  }

  List<BoxShadow>? _getGlow(PharmaConnectPalette p, Color color) {
    // Halo réservé au thème sombre : sur fond clair, il salit le badge.
    if (!showGlow || !p.isDark) return null;
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ];
  }
}
