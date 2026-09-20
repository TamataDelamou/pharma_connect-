import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/personalized_reward_provider.dart';
import '../models/personalized_reward.dart';

class PersonalizedRewardsScreen extends StatefulWidget {
  const PersonalizedRewardsScreen({super.key});

  @override
  State<PersonalizedRewardsScreen> createState() =>
      _PersonalizedRewardsScreenState();
}

class _PersonalizedRewardsScreenState extends State<PersonalizedRewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      if (userId != null) {
        context.read<PersonalizedRewardProvider>().loadActiveRewards(userId);
        context.read<PersonalizedRewardProvider>().loadAllRewards(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalizedRewardProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '🎁 Récompenses personnalisées',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: provider.isGenerating
                      ? null
                      : () async {
                          final userId = SupabaseService().currentUser?.id;
                          if (userId != null) {
                            await provider.generateRewards(userId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nouvelles récompenses générées !',
                                ),
                                backgroundColor:
                                    PharmaConnectColors.accentGreen,
                              ),
                            );
                          }
                        },
                  icon: provider.isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    provider.isGenerating ? 'Génération...' : 'Générer',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentPurple,
                    foregroundColor: PharmaConnectColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Offres adaptées à vos habitudes de santé',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: provider.isLoading
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
                                provider.loadActiveRewards(userId);
                              }
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : provider.activeRewards.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune récompense disponible',
                            style: PharmaConnectTypography.heading3,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Générez des récompenses en restant actif',
                            style: PharmaConnectTypography.body2,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.activeRewards.length,
                      itemBuilder: (context, index) {
                        final reward = provider.activeRewards[index];
                        // Phase 4 (module loyalty) : GlassCard n'expose pas
                        // de paramètre `margin` - même défaut de compilation
                        // déjà rencontré dans professional_reviews_screen.dart
                        // (Phase 3) et loyalty_pharmacy_select_screen.dart
                        // ci-dessus. Corrigé pareillement (Padding).
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _rewardIcon(reward.rewardType),
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reward.title,
                                            style: PharmaConnectTypography.body1
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          if (reward.description != null)
                                            Text(
                                              reward.description!,
                                              style:
                                                  PharmaConnectTypography.body2,
                                            ),
                                          if (reward.discountPercentage != null)
                                            Text(
                                              '${reward.discountPercentage}% de réduction',
                                              style: TextStyle(
                                                color: PharmaConnectColors
                                                    .accentGreen,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          if (reward.pointsCost != null)
                                            Text(
                                              '${reward.pointsCost} points',
                                              style: TextStyle(
                                                color: PharmaConnectColors
                                                    .accentPurple,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (reward.expiresAt != null)
                                      Text(
                                        'Expire le ${_formatDate(reward.expiresAt!)}',
                                        style: PharmaConnectTypography.micro,
                                      ),
                                    PrimaryButton(
                                      label: 'Utiliser',
                                      onPressed: () async {
                                        await provider.useReward(reward.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Récompense utilisée !',
                                              ),
                                              backgroundColor:
                                                  PharmaConnectColors
                                                      .accentGreen,
                                            ),
                                          );
                                        }
                                      },
                                      height: 30,
                                      width: 100,
                                      fontSize: 12,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _rewardIcon(String type) {
    switch (type) {
      case 'discount':
        return '💰';
      case 'bonus_points':
        return '⭐';
      case 'free_item':
        return '🎁';
      case 'premium_access':
        return '👑';
      default:
        return '🎯';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
