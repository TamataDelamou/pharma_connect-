import 'package:flutter/material.dart';
import '../models/health_record.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class ConditionTile extends StatelessWidget {
  final MedicalCondition condition;

  const ConditionTile({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(
            Icons.health_and_safety,
            color: context.palette.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(condition.name, style: context.text.body1)),
          if (condition.status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(
                  context,
                  condition.status!,
                ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                condition.status!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _statusColor(context, condition.status!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'active':
        return context.palette.warning;
      case 'resolved':
        return context.palette.success;
      case 'chronic':
        return context.palette.secondary;
      default:
        return context.palette.textSecondary;
    }
  }
}
