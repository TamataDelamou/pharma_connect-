import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/family_challenge_provider.dart';

class FamilyChallengeDetailScreen extends StatefulWidget {
  final String challengeId;

  const FamilyChallengeDetailScreen({super.key, required this.challengeId});

  @override
  State<FamilyChallengeDetailScreen> createState() =>
      _FamilyChallengeDetailScreenState();
}

class _FamilyChallengeDetailScreenState
    extends State<FamilyChallengeDetailScreen> {
  final _contributionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyChallengeProvider>().loadChallenge(widget.challengeId);
    });
  }

  @override
  void dispose() {
    _contributionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FamilyChallengeProvider>();
    final challenge = provider.selectedChallenge;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (challenge == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Défi introuvable',
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        ),
      );
    }

    final userId = SupabaseService().currentUser?.id;
    final isMember = true; // Check if user is part of the family link

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
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
                      'Détail du défi',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: challenge.isCompleted
                          ? PharmaConnectColors.accentGreen
                          : PharmaConnectColors.accentCyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                challenge.typeLabel,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Défi ${challenge.typeLabel}',
                                      style: PharmaConnectTypography.heading3,
                                    ),
                                    Text(
                                      'Cible: ${challenge.targetValue}',
                                      style: PharmaConnectTypography.body2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Progress
                          Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: challenge.progressPercentage,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: challenge.isCompleted
                                        ? PharmaConnectColors.accentGreen
                                        : PharmaConnectColors.accentCyan,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progression: ${challenge.progress}/${challenge.targetValue}',
                                style: PharmaConnectTypography.micro,
                              ),
                              Text(
                                '${(challenge.progressPercentage * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: challenge.isCompleted
                                      ? PharmaConnectColors.accentGreen
                                      : PharmaConnectColors.accentCyan,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contributions
                    if (provider.contributions.isNotEmpty) ...[
                      const Text(
                        'Contributions',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...provider.contributions.map((contribution) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: PharmaConnectColors.accentCyan
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  contribution.patientName?[0] ?? '?',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: PharmaConnectColors.accentCyan,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  contribution.patientName ??
                                      contribution.patientId,
                                  style: PharmaConnectTypography.body2,
                                ),
                              ),
                              Text(
                                '+${contribution.contributionValue}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: PharmaConnectColors.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),

                    // Add contribution
                    if (!challenge.isCompleted && isMember) ...[
                      GlassCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _contributionController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Contribuer...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PrimaryButton(
                              label: 'Ajouter',
                              onPressed: () async {
                                final value = int.tryParse(
                                  _contributionController.text,
                                );
                                if (value == null || value <= 0) return;
                                await provider.addContribution(
                                  challengeId: challenge.id,
                                  patientId: userId!,
                                  value: value,
                                );
                                _contributionController.clear();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Contribution ajoutée !'),
                                      backgroundColor:
                                          PharmaConnectColors.accentGreen,
                                    ),
                                  );
                                  provider.loadChallenge(widget.challengeId);
                                }
                              },
                              width: 100,
                              height: 50,
                            ),
                          ],
                        ),
                      ),
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
}
