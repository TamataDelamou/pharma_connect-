import 'package:flutter/material.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/recall.dart';
import 'recall_status_chip.dart';

class RecallCard extends StatelessWidget {
  final Recall recall;
  final VoidCallback onTap;

  const RecallCard({super.key, required this.recall, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Indicateur de sévérité
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: recall.severityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recall.referenceNumber,
                  style: PharmaConnectTypography.body2,
                ),
                Text(
                  recall.title,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${recall.affectedBatches.length} lots affectés',
                      style: PharmaConnectTypography.micro,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${recall.totalAffectedUnits ?? 0} unités',
                      style: PharmaConnectTypography.micro,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: recall.severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recall.severityLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: recall.severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Statut
          RecallStatusChip(status: recall.status, compact: true),
        ],
      ),
    );
  }
}
