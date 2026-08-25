import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../badges/status_badge.dart';
import 'glass_card.dart';

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
                      color: statusColor.withValues(alpha: 0.4),
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
              status: _mapStatusToBadge(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  StatusBadgeType _mapStatusToBadge(Color color) {
    if (color == PharmaConnectColors.accentGreen) {
      return StatusBadgeType.success;
    } else if (color == PharmaConnectColors.accentOrange) {
      return StatusBadgeType.warning;
    } else if (color == PharmaConnectColors.accentRed) {
      return StatusBadgeType.danger;
    } else if (color == PharmaConnectColors.accentPurple) {
      return StatusBadgeType.kernel;
    }
    return StatusBadgeType.info;
  }
}
