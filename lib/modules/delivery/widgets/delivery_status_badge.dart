import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../models/delivery_status.dart';

class DeliveryStatusBadge extends StatelessWidget {
  final DeliveryStatus status;

  const DeliveryStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(status);
    final label = status.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.scheduled:
        return PharmaConnectColors.accentOrange;
      case DeliveryStatus.preparing:
        return PharmaConnectColors.accentCyan;
      case DeliveryStatus.inProgress:
        return PharmaConnectColors.accentPurple;
      case DeliveryStatus.arrived:
        return PharmaConnectColors.accentGreen;
      case DeliveryStatus.delivered:
        return PharmaConnectColors.textSecondary;
      case DeliveryStatus.cancelled:
        return PharmaConnectColors.accentRed;
    }
  }
}
