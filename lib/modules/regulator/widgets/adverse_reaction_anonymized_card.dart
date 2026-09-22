import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/adverse_reaction_anonymized.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-5 / RG-REG-02 : carte
// dédiée à la vue anonymisée. Volontairement SANS `onTap` : il n'existe
// aucun écran de détail nominatif accessible depuis ce mode (un compte
// 'regulateur' ne doit jamais pouvoir naviguer vers la donnée brute).
class AdverseReactionAnonymizedCard extends StatelessWidget {
  final AdverseReactionAnonymized reaction;

  const AdverseReactionAnonymizedCard({super.key, required this.reaction});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: _severityColor(reaction.severity),
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
                        reaction.medicationGenericName ?? 'Médicament non renseigné',
                        style: PharmaConnectTypography.body1.copyWith(
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
                          reaction.severity,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reaction.severityLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _severityColor(reaction.severity),
                        ),
                      ),
                    ),
                  ],
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
                          reaction.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reaction.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(reaction.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(reaction.createdAt),
                      style: PharmaConnectTypography.micro,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'mild':
        return PharmaConnectColors.accentCyan;
      case 'moderate':
        return PharmaConnectColors.accentOrange;
      case 'severe':
        return PharmaConnectColors.accentRed;
      case 'life_threatening':
        return PharmaConnectColors.accentRed;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return PharmaConnectColors.accentOrange;
      case 'under_review':
        return PharmaConnectColors.accentCyan;
      case 'investigating':
        return PharmaConnectColors.accentAmber;
      case 'closed':
        return PharmaConnectColors.accentGreen;
      case 'rejected':
        return PharmaConnectColors.accentRed;
      default:
        return PharmaConnectColors.textSecondary;
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
