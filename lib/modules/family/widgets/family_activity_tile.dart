import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import '../models/family_activity.dart';

class FamilyActivityTile extends StatelessWidget {
  final FamilyActivity activity;
  final VoidCallback? onDelete;

  const FamilyActivityTile({super.key, required this.activity, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Text(
            _activityIcon(activity.activityType),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      activity.patientName ?? activity.patientId,
                      style: PharmaConnectTypography.body2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(activity.recordedAt),
                      style: PharmaConnectTypography.micro,
                    ),
                  ],
                ),
                Text(
                  activity.note ?? activity.typeLabel,
                  style: PharmaConnectTypography.body2,
                ),
                if (activity.value != null)
                  Text(
                    'Valeur: ${activity.value}',
                    style: PharmaConnectTypography.micro,
                  ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  String _activityIcon(String type) {
    switch (type) {
      case 'walk':
        return '🚶';
      case 'water':
        return '💧';
      case 'fruits':
        return '🍎';
      case 'meditation':
        return '🧘';
      case 'consultation':
        return '🩺';
      case 'medication':
        return '💊';
      default:
        return '📋';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }
}
