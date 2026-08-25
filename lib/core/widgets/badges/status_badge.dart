import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';

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
    final color = _getColor();
    final glow = _getGlow();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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

  Color _getColor() {
    switch (status) {
      case StatusBadgeType.success:
        return PharmaConnectColors.accentGreen;
      case StatusBadgeType.warning:
        return PharmaConnectColors.accentOrange;
      case StatusBadgeType.danger:
        return PharmaConnectColors.accentRed;
      case StatusBadgeType.info:
        return PharmaConnectColors.accentCyan;
      case StatusBadgeType.kernel:
        return PharmaConnectColors.accentPurple;
      case StatusBadgeType.neutral:
        return PharmaConnectColors.textSecondary;
    }
  }

  List<BoxShadow>? _getGlow() {
    if (!showGlow) return null;
    final color = _getColor();
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ];
  }
}
