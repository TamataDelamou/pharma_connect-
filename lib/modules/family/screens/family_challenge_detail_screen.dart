import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/family_challenge_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

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
            style: context.text.body2.copyWith(color: context.palette.danger),
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
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Détail du défi',
                      style: context.text.heading2,
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
                        ? context.palette.success.withValues(alpha: 0.15)
                        : context.palette.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    challenge.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: challenge.isCompleted
                          ? context.palette.success
                          : context.palette.primary,
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
                                      style: context.text.heading3,
                                    ),
                                    Text(
                                      'Cible: ${challenge.targetValue}',
                                      style: context.text.body2,
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
                                  color: context.palette.veil(0.24),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: challenge.progressPercentage,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: challenge.isCompleted
                                        ? context.palette.success
                                        : context.palette.primary,
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
                                style: context.text.micro,
                              ),
                              Text(
                                '${(challenge.progressPercentage * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: challenge.isCompleted
                                      ? context.palette.success
                                      : context.palette.primary,
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
                      Text('Contributions', style: context.text.heading3),
                      const SizedBox(height: 8),
                      ...provider.contributions.map((contribution) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: context.palette.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.palette.borderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: context.palette.primary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  contribution.patientName?[0] ?? '?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.palette.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  contribution.patientName ??
                                      contribution.patientId,
                                  style: context.text.body2,
                                ),
                              ),
                              Text(
                                '+${contribution.contributionValue}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: context.palette.success,
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
                                    SnackBar(
                                      content: Text('Contribution ajoutée !'),
                                      backgroundColor: context.palette.success,
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
