import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/adverse_reaction.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class AdverseReactionCard extends StatelessWidget {
  final AdverseReaction reaction;
  final VoidCallback onTap;

  const AdverseReactionCard({
    super.key,
    required this.reaction,
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
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: _severityColor(context, reaction.severity),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reaction.medicationName,
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _severityColor(
                          context,
                          reaction.severity,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reaction.severityLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _severityColor(context, reaction.severity),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  reaction.symptoms,
                  style: context.text.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          context,
                          reaction.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reaction.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(context, reaction.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(reaction.reportedAt),
                      style: context.text.micro,
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

  Color _severityColor(BuildContext context, String severity) {
    switch (severity) {
      case 'mild':
        return context.palette.primary;
      case 'moderate':
        return context.palette.warning;
      case 'severe':
        return context.palette.danger;
      case 'life_threatening':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return context.palette.warning;
      case 'under_review':
        return context.palette.primary;
      case 'investigating':
        return context.palette.warningStrong;
      case 'closed':
        return context.palette.success;
      case 'rejected':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
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
