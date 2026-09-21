import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import '../models/health_record.dart';

class ConditionTile extends StatelessWidget {
  final MedicalCondition condition;

  const ConditionTile({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.health_and_safety,
            color: PharmaConnectColors.accentCyan,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(condition.name, style: PharmaConnectTypography.body1),
          ),
          if (condition.status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(condition.status!).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                condition.status!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _statusColor(condition.status!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return PharmaConnectColors.accentOrange;
      case 'resolved':
        return PharmaConnectColors.accentGreen;
      case 'chronic':
        return PharmaConnectColors.accentPurple;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }
}
