import 'package:flutter/material.dart';
import '../models/delivery_status.dart';
import '../../../core/theme/palette.dart';

class DeliveryStatusBadge extends StatelessWidget {
  final DeliveryStatus status;

  const DeliveryStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context, status);
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

  Color _getColor(BuildContext context, DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.scheduled:
        return context.palette.warning;
      case DeliveryStatus.preparing:
        return context.palette.primary;
      case DeliveryStatus.inProgress:
        return context.palette.secondary;
      case DeliveryStatus.arrived:
        return context.palette.success;
      case DeliveryStatus.delivered:
        return context.palette.textSecondary;
      case DeliveryStatus.cancelled:
        return context.palette.danger;
    }
  }
}
