import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/loyalty_ai_provider.dart';
import '../models/health_challenge.dart';

class ChallengesDashboardScreen extends StatefulWidget {
  const ChallengesDashboardScreen({super.key});

  @override
  State<ChallengesDashboardScreen> createState() =>
      _ChallengesDashboardScreenState();
}

class _ChallengesDashboardScreenState extends State<ChallengesDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      if (userId != null) {
        context.read<LoyaltyAIProvider>().generateChallenges(userId);
        context.read<LoyaltyAIProvider>().loadRecommendations(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoyaltyAIProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏆 Défis santé',
                    style: PharmaConnectTypography.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Relevez des défis et gagnez des points',
                    style: PharmaConnectTypography.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                ElevatedButton.icon(
                  onPressed: provider.isGenerating
                      ? null
                      : () {
                          final userId = SupabaseService().currentUser?.id;
                          if (userId != null) {
                            provider.generateChallenges(userId);
                          }
                        },
                  icon: provider.isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              PharmaConnectColors.textOnAccent,
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    provider.isGenerating ? 'Génération...' : 'Rafraîchir',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: provider.isGenerating || provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: PharmaConnectColors.accentRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style: PharmaConnectTypography.body2.copyWith(
                              color: PharmaConnectColors.accentRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: () {
                              provider.clearError();
                              final userId = SupabaseService().currentUser?.id;
                              if (userId != null) {
                                provider.generateChallenges(userId);
                              }
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Daily challenge
                          if (provider.challenges.isNotEmpty) ...[
                            _buildChallengeCard(
                              provider.challenges.first,
                              provider,
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Recommendations
                          if (provider.recommendations.isNotEmpty) ...[
                            const Text(
                              '💡 Recommandations personnalisées',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 8),
                            ...provider.recommendations.map((rec) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      rec['icon'] ?? '📋',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rec['title'] ?? '',
                                            style: PharmaConnectTypography.body1
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            rec['description'] ?? '',
                                            style:
                                                PharmaConnectTypography.body2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],

                          const SizedBox(height: 16),

                          // Other challenges
                          if (provider.challenges.length > 1) ...[
                            const Text(
                              '📋 Tous les défis',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 8),
                            ...provider.challenges.skip(1).map((challenge) {
                              return _buildChallengeCard(
                                challenge,
                                provider,
                                compact: true,
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
    HealthChallenge challenge,
    LoyaltyAIProvider provider, {
    bool compact = false,
  }) {
    final progress = provider.getProgressForChallenge(challenge.id);
    final isCompleted = progress?.completed ?? false;
    final percentage = progress?.progressPercentage ?? 0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                challenge.name,
                style: compact
                    ? PharmaConnectTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      )
                    : PharmaConnectTypography.heading3,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _difficultyColor(
                    challenge.difficulty,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  challenge.difficultyLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _difficultyColor(challenge.difficulty),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? PharmaConnectColors.accentGreen.withValues(alpha: 0.15)
                      : PharmaConnectColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isCompleted ? '✅ Terminé' : 'En cours',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isCompleted
                        ? PharmaConnectColors.accentGreen
                        : PharmaConnectColors.accentCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (!compact && challenge.description != null)
            Text(challenge.description!, style: PharmaConnectTypography.body2),
          if (!compact) const SizedBox(height: 8),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? PharmaConnectColors.accentGreen
                              : PharmaConnectColors.accentCyan,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${progress?.progress ?? 0}/${challenge.target}',
                style: PharmaConnectTypography.micro.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Points and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🎯 ${challenge.points} points',
                style: PharmaConnectTypography.micro,
              ),
              if (!isCompleted)
                PrimaryButton(
                  label: '🚀 Mettre à jour',
                  onPressed: () async {
                    final userId = SupabaseService().currentUser?.id;
                    if (userId == null) return;
                    // Show dialog to record progress
                    _showProgressDialog(context, challenge, userId, provider);
                  },
                  height: 30,
                  width: 120,
                  fontSize: 12,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return PharmaConnectColors.accentGreen;
      case 'medium':
        return PharmaConnectColors.accentAmber;
      case 'hard':
        return PharmaConnectColors.accentRed;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }

  void _showProgressDialog(
    BuildContext context,
    HealthChallenge challenge,
    String userId,
    LoyaltyAIProvider provider,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: Text('Mettre à jour : ${challenge.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Progression actuelle : ${provider.getProgressForChallenge(challenge.id)?.progress ?? 0}/${challenge.target}',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nouvelle progression (${challenge.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = int.tryParse(controller.text);
              if (value == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un nombre valide'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await provider.updateProgress(
                patientId: userId,
                challengeId: challenge.id,
                increment: value,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progression mise à jour !'),
                    backgroundColor: PharmaConnectColors.accentGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}
