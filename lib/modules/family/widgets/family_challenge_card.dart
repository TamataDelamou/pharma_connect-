import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/family_challenge.dart';

class FamilyChallengeCard extends StatelessWidget {
  final FamilyChallenge challenge;
  final VoidCallback onTap;

  const FamilyChallengeCard({
    super.key,
    required this.challenge,
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
            height: 40,
            decoration: BoxDecoration(
              color: challenge.isCompleted
                  ? PharmaConnectColors.accentGreen
                  : PharmaConnectColors.accentCyan,
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
                    Text(
                      challenge.typeLabel,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Défi ${challenge.typeLabel}',
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
                        color: challenge.isCompleted
                            ? PharmaConnectColors.accentGreen.withValues(
                                alpha: 0.15,
                              )
                            : PharmaConnectColors.accentCyan.withValues(
                                alpha: 0.15,
                              ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        challenge.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: challenge.isCompleted
                              ? PharmaConnectColors.accentGreen
                              : PharmaConnectColors.accentCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: challenge.progressPercentage,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: challenge.isCompleted
                              ? PharmaConnectColors.accentGreen
                              : PharmaConnectColors.accentCyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${challenge.progress}/${challenge.targetValue}',
                  style: PharmaConnectTypography.micro,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }
}
