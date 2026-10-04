import 'package:flutter/material.dart';
import '../models/family_activity.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class FamilyActivityTile extends StatelessWidget {
  final FamilyActivity activity;
  final VoidCallback? onDelete;

  const FamilyActivityTile({super.key, required this.activity, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.palette.borderSubtle),
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
                      style: context.text.body2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(activity.recordedAt),
                      style: context.text.micro,
                    ),
                  ],
                ),
                Text(
                  activity.note ?? activity.typeLabel,
                  style: context.text.body2,
                ),
                if (activity.value != null)
                  Text('Valeur: ${activity.value}', style: context.text.micro),
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
