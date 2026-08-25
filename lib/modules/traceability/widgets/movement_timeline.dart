import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/batch_movement.dart';

class MovementTimeline extends StatelessWidget {
  final List<BatchMovement> movements;

  const MovementTimeline({super.key, required this.movements});

  @override
  Widget build(BuildContext context) {
    final sortedMovements = List<BatchMovement>.from(movements)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: sortedMovements.map((movement) {
        final isLast = movement == sortedMovements.last;
        return _buildMovementItem(movement, isLast);
      }).toList(),
    );
  }

  Widget _buildMovementItem(BatchMovement movement, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne verticale + point
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PharmaConnectColors.accentCyan,
                border: Border.all(
                  color: PharmaConnectColors.accentCyan.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(height: 4),
              Container(
                width: 2,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ],
          ],
        ),
        const SizedBox(width: 12),
        // Contenu
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movement.typeLabel,
                style: PharmaConnectTypography.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${movement.fromLocation} → ${movement.toLocation}',
                style: PharmaConnectTypography.body2,
              ),
              Row(
                children: [
                  Text(
                    _formatDateTime(movement.timestamp),
                    style: PharmaConnectTypography.micro,
                  ),
                  if (movement.temperature != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.thermostat,
                      size: 12,
                      color: PharmaConnectColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${movement.temperature}°C',
                      style: PharmaConnectTypography.micro,
                    ),
                  ],
                  if (movement.trackingNumber != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      '📦 ${movement.trackingNumber}',
                      style: PharmaConnectTypography.micro,
                    ),
                  ],
                ],
              ),
              if (movement.notes != null) ...[
                const SizedBox(height: 2),
                Text(
                  movement.notes!,
                  style: PharmaConnectTypography.micro.copyWith(
                    color: PharmaConnectColors.textSecondary.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
