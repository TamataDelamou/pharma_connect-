import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/intervention.dart';
import '../models/homecare_status.dart';

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
              color: _statusColor(intervention.status).withValues(alpha: 0.15),
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
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  intervention.professionalName ?? intervention.professionalId,
                  style: PharmaConnectTypography.body2,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.home, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        intervention.address,
                        style: PharmaConnectTypography.micro,
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
                          intervention.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        intervention.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(intervention.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Color _statusColor(HomecareStatus status) {
    switch (status) {
      case HomecareStatus.pending:
        return PharmaConnectColors.accentOrange;
      case HomecareStatus.confirmed:
        return PharmaConnectColors.accentGreen;
      case HomecareStatus.inProgress:
        return PharmaConnectColors.accentCyan;
      case HomecareStatus.completed:
        return PharmaConnectColors.accentPurple;
      case HomecareStatus.cancelled:
        return PharmaConnectColors.accentRed;
      case HomecareStatus.missed:
        return PharmaConnectColors.textSecondary;
    }
  }
}
