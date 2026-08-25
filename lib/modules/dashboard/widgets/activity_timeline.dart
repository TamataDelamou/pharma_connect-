import 'package:flutter/material.dart';
import '../../../core/theme/typography.dart';
import '../models/dashboard_data.dart';

class ActivityTimeline extends StatelessWidget {
  final List<ActivityItem> activities;

  const ActivityTimeline({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activité récente', style: PharmaConnectTypography.heading3),
        const SizedBox(height: 16),
        ...activities.map((item) => _buildTimelineItem(item)),
      ],
    );
  }

  Widget _buildTimelineItem(ActivityItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cercle icône
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: item.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 12),
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${item.subtitle} • ${item.timeAgo}',
                  style: PharmaConnectTypography.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
