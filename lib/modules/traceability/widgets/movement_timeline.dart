import 'package:flutter/material.dart';
import '../models/batch_movement.dart';
import '../../../core/theme/palette.dart';

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
        return _buildMovementItem(context, movement, isLast);
      }).toList(),
    );
  }

  Widget _buildMovementItem(
    BuildContext context,
    BatchMovement movement,
    bool isLast,
  ) {
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
                color: context.palette.primary,
                border: Border.all(
                  color: context.palette.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(height: 4),
              Container(width: 2, height: 40, color: context.palette.border),
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
                style: context.text.body1.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${movement.fromLocation} → ${movement.toLocation}',
                style: context.text.body2,
              ),
              Row(
                children: [
                  Text(
                    _formatDateTime(movement.timestamp),
                    style: context.text.micro,
                  ),
                  if (movement.temperature != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.thermostat,
                      size: 12,
                      color: context.palette.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${movement.temperature}°C',
                      style: context.text.micro,
                    ),
                  ],
                  if (movement.trackingNumber != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      '📦 ${movement.trackingNumber}',
                      style: context.text.micro,
                    ),
                  ],
                ],
              ),
              if (movement.notes != null) ...[
                const SizedBox(height: 2),
                Text(
                  movement.notes!,
                  style: context.text.micro.copyWith(
                    color: context.palette.textSecondary.withValues(alpha: 0.7),
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
