import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/intervention.dart';
import '../models/homecare_status.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class InterventionCard extends StatelessWidget {
  final Intervention intervention;
  final VoidCallback onTap;

  const InterventionCard({
    super.key,
    required this.intervention,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor(
                context,
                intervention.status,
              ).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                intervention.status.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intervention.patientName ?? intervention.patientId,
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  intervention.professionalName ?? intervention.professionalId,
                  style: context.text.body2,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.home,
                      size: 14,
                      color: context.palette.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        intervention.address,
                        style: context.text.micro,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          context,
                          intervention.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        intervention.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(context, intervention.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, HomecareStatus status) {
    switch (status) {
      case HomecareStatus.pending:
        return context.palette.warning;
      case HomecareStatus.confirmed:
        return context.palette.success;
      case HomecareStatus.inProgress:
        return context.palette.primary;
      case HomecareStatus.completed:
        return context.palette.secondary;
      case HomecareStatus.cancelled:
        return context.palette.danger;
      case HomecareStatus.missed:
        return context.palette.textSecondary;
    }
  }
}
