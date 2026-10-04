import 'package:flutter/material.dart';

import '../badges/status_badge.dart';
import 'glass_card.dart';
import '../../theme/palette.dart';

class StatusCard extends StatelessWidget {
  final Widget child;
  final Color statusColor;
  final String statusLabel;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.child,
    required this.statusColor,
    required this.statusLabel,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Les écrans non migrés passent encore une constante du thème sombre.
    final statusColor = this.statusColor;
    return GlassCard(
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(
                        alpha: palette.isDark ? 0.4 : 0.15,
                      ),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: child),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: StatusBadge(
              label: statusLabel,
              status: _mapStatusToBadge(palette, statusColor),
            ),
          ),
        ],
      ),
    );
  }

  StatusBadgeType _mapStatusToBadge(PharmaConnectPalette p, Color color) {
    if (color == p.success) {
      return StatusBadgeType.success;
    } else if (color == p.warning) {
      return StatusBadgeType.warning;
    } else if (color == p.danger) {
      return StatusBadgeType.danger;
    } else if (color == p.secondary) {
      return StatusBadgeType.kernel;
    }
    return StatusBadgeType.info;
  }
}
