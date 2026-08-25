import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';

class DeliveryTimeline extends StatelessWidget {
  final Delivery delivery;

  const DeliveryTimeline({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildStep(
        icon: Icons.schedule,
        label: 'Programmée',
        time: delivery.scheduledAt,
        isCompleted: true,
      ),
      _buildStep(
        icon: Icons.inventory_2,
        label: 'Préparation',
        time: delivery.startedAt ?? delivery.scheduledAt,
        isCompleted: delivery.status != DeliveryStatus.scheduled,
      ),
      _buildStep(
        icon: Icons.delivery_dining,
        label: 'En route',
        time: delivery.startedAt,
        isCompleted:
            delivery.status == DeliveryStatus.inProgress ||
            delivery.status == DeliveryStatus.arrived ||
            delivery.status == DeliveryStatus.delivered,
        isActive: delivery.status == DeliveryStatus.inProgress,
      ),
      _buildStep(
        icon: Icons.location_on,
        label: 'Arrivé',
        time: delivery.arrivedAt,
        isCompleted:
            delivery.status == DeliveryStatus.arrived ||
            delivery.status == DeliveryStatus.delivered,
        isActive: delivery.status == DeliveryStatus.arrived,
      ),
      _buildStep(
        icon: Icons.check_circle,
        label: 'Livré',
        time: delivery.deliveredAt,
        isCompleted: delivery.status == DeliveryStatus.delivered,
        isActive: delivery.status == DeliveryStatus.delivered,
      ),
    ];

    return Column(
      children: steps.map((step) {
        final isLast = step == steps.last;
        return _buildTimelineItem(step, isLast);
      }).toList(),
    );
  }

  _buildStep({
    required IconData icon,
    required String label,
    required DateTime? time,
    required bool isCompleted,
    bool isActive = false,
  }) {
    return _TimelineStep(
      icon: icon,
      label: label,
      time: time,
      isCompleted: isCompleted,
      isActive: isActive,
    );
  }

  Widget _buildTimelineItem(_TimelineStep step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône et ligne
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.isCompleted || step.isActive
                    ? PharmaConnectColors.accentCyan.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: step.isCompleted || step.isActive
                      ? PharmaConnectColors.accentCyan
                      : Colors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Icon(
                step.icon,
                color: step.isCompleted || step.isActive
                    ? PharmaConnectColors.accentCyan
                    : PharmaConnectColors.textSecondary.withValues(alpha: 0.3),
                size: 16,
              ),
            ),
            if (!isLast) ...[
              const SizedBox(height: 4),
              Container(
                width: 2,
                height: 40,
                color: step.isCompleted
                    ? PharmaConnectColors.accentCyan
                    : Colors.white.withValues(alpha: 0.1),
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
                step.label,
                style: PharmaConnectTypography.body1.copyWith(
                  fontWeight: step.isActive ? FontWeight.w600 : FontWeight.w400,
                  color: step.isCompleted || step.isActive
                      ? PharmaConnectColors.textPrimary
                      : PharmaConnectColors.textSecondary.withValues(
                          alpha: 0.3,
                        ),
                ),
              ),
              if (step.time != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatTime(step.time!),
                  style: PharmaConnectTypography.micro.copyWith(
                    color: step.isCompleted || step.isActive
                        ? PharmaConnectColors.textSecondary
                        : PharmaConnectColors.textSecondary.withValues(
                            alpha: 0.3,
                          ),
                  ),
                ),
              ],
              if (step.isActive && step.label == 'En route') ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: PharmaConnectColors.accentPurple.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '⏱ ${delivery.estimatedArrival}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: PharmaConnectColors.accentPurple,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) {
      return 'Il y a ${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'Il y a ${diff.inMinutes}m';
    } else {
      return "À l'instant";
    }
  }
}

class _TimelineStep {
  final IconData icon;
  final String label;
  final DateTime? time;
  final bool isCompleted;
  final bool isActive;

  _TimelineStep({
    required this.icon,
    required this.label,
    this.time,
    required this.isCompleted,
    this.isActive = false,
  });
}
