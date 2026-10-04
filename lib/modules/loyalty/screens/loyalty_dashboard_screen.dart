import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/loyalty_provider.dart';
import '../models/loyalty_account.dart';
import '../models/loyalty_reward.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class LoyaltyDashboardScreen extends StatefulWidget {
  // Audit Module 16 (FID, 29/08/2026) : devenu obligatoire — cet écran est
  // désormais toujours atteint via `/loyalty/:pharmacyId` (poussé depuis
  // `LoyaltyPharmacySelectScreen`), jamais directement en route racine. Le
  // repli précédent sur la chaîne littérale 'default_pharmacy' (ni un UUID
  // ni une officine réelle) faisait échouer toute requête réelle
  // (« invalid input syntax for type uuid ») dès que ce paramètre était
  // absent — ce qui était systématiquement le cas : la route ne le
  // fournissait jamais.
  final String pharmacyId;

  const LoyaltyDashboardScreen({super.key, required this.pharmacyId});

  @override
  State<LoyaltyDashboardScreen> createState() => _LoyaltyDashboardScreenState();
}

class _LoyaltyDashboardScreenState extends State<LoyaltyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      if (userId != null) {
        context.read<LoyaltyProvider>().loadAccount(userId, widget.pharmacyId);
        context.read<LoyaltyProvider>().loadRewards(widget.pharmacyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoyaltyProvider>();
    final account = provider.account;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: context.palette.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Programme de fidélité',
                        style: context.text.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gagnez des points à chaque achat',
                        style: context.text.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
              ],
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
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.palette.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: context.text.body2.copyWith(
                              color: context.palette.danger,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: () {
                              provider.clearError();
                              final userId = SupabaseService().currentUser?.id;
                              if (userId != null) {
                                provider.loadAccount(userId, widget.pharmacyId);
                              }
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : account == null
                  ? Center(
                      child: Text(
                        'Aucun compte de fidélité trouvé',
                        style: context.text.body2,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Account summary
                          GlassCard(
                            glow: true,
                            glowColor: _tierColor(account.tier),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${account.tierEmoji} ${account.tierLabel}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: _tierColor(account.tier),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Points : ${account.pointsBalance}',
                                      style: context.text.kpiMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (account.pointsToNextTier > 0)
                                  Text(
                                    '${account.pointsToNextTier} points pour le prochain niveau',
                                    style: context.text.body2,
                                  ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _progressToNextTier(account),
                                  backgroundColor: context.palette.veil(0.24),
                                  color: _tierColor(account.tier),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${account.totalPointsEarned} points gagnés • ${account.totalPointsRedeemed} points utilisés',
                                  style: context.text.micro,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Rewards catalog
                          Text(
                            'Récompenses disponibles',
                            style: context.text.heading3,
                          ),
                          const SizedBox(height: 8),
                          if (provider.rewards.isEmpty)
                            Text(
                              'Aucune récompense disponible',
                              style: context.text.body2,
                            )
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: provider.rewards.map((reward) {
                                return GestureDetector(
                                  onTap: () {
                                    _showRedeemDialog(context, reward);
                                  },
                                  child: Container(
                                    width: 160,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.palette.surfaceMuted,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: context.palette.borderSubtle,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reward.name,
                                          style: context.text.body1.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${reward.pointsRequired} points',
                                          style: context.text.micro.copyWith(
                                            color: context.palette.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        PrimaryButton(
                                          label: 'Échanger',
                                          onPressed: () => _showRedeemDialog(
                                            context,
                                            reward,
                                          ),
                                          width: double.infinity,
                                          height: 32,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 24),

                          // Recent transactions
                          Text(
                            'Activité récente',
                            style: context.text.heading3,
                          ),
                          const SizedBox(height: 8),
                          if (provider.transactions.isEmpty)
                            Text('Aucune activité', style: context.text.body2)
                          else
                            ...provider.transactions.take(5).map((tx) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: context.palette.borderSubtle,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      tx.typeIcon,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.typeLabel,
                                            style: context.text.body2,
                                          ),
                                          Text(
                                            tx.description ?? '',
                                            style: context.text.micro,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      tx.amount > 0
                                          ? '+${tx.amount}'
                                          : '${tx.amount}',
                                      style: TextStyle(
                                        color: tx.amount > 0
                                            ? context.palette.success
                                            : context.palette.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _progressToNextTier(LoyaltyAccount account) {
    switch (account.tier) {
      case 'bronze':
        return account.pointsBalance / 200;
      case 'silver':
        return (account.pointsBalance - 200) / 300;
      case 'gold':
        return (account.pointsBalance - 500) / 500;
      default:
        return 1.0;
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'bronze':
        return PharmaConnectFixedColors.tierBronze;
      case 'silver':
        return PharmaConnectFixedColors.tierSilver;
      case 'gold':
        return PharmaConnectFixedColors.tierGold;
      case 'platinum':
        return PharmaConnectFixedColors.tierPlatinum;
      default:
        return context.palette.textSecondary;
    }
  }

  void _showRedeemDialog(BuildContext context, LoyaltyReward reward) {
    final provider = context.read<LoyaltyProvider>();
    final account = provider.account;

    if (account == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: Text('Échanger : ${reward.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Points requis : ${reward.pointsRequired}'),
            Text('Votre solde : ${account.pointsBalance}'),
            if (account.pointsBalance < reward.pointsRequired)
              Text(
                'Points insuffisants',
                style: TextStyle(color: context.palette.danger),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: account.pointsBalance >= reward.pointsRequired
                ? () async {
                    Navigator.pop(ctx);
                    final success = await provider.redeemPoints(
                      reward.pointsRequired,
                      description: 'Récompense : ${reward.name}',
                    );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Récompense échangée avec succès !'),
                          backgroundColor: context.palette.success,
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.primary,
              foregroundColor: context.palette.onPrimary,
            ),
            child: const Text('Échanger'),
          ),
        ],
      ),
    );
  }
}
