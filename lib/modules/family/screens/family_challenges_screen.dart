import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../providers/family_challenge_provider.dart';
import '../widgets/family_challenge_card.dart';

class FamilyChallengesScreen extends StatefulWidget {
  final String familyLinkId;

  const FamilyChallengesScreen({super.key, required this.familyLinkId});

  @override
  State<FamilyChallengesScreen> createState() => _FamilyChallengesScreenState();
}

class _FamilyChallengesScreenState extends State<FamilyChallengesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyChallengeProvider>().loadChallenges(
        widget.familyLinkId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FamilyChallengeProvider>();

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
                      '👨‍👩‍👧‍👦 Défis familiaux',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                // C232 : écran absent — « Créer » un défi familial
                // (/family/challenges/new) masqué.
              ],
            ),
            const SizedBox(height: 24),

            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(FamilyChallengeProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
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
              textAlign: TextAlign.center,
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                provider.loadChallenges(widget.familyLinkId);
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.challenges.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Aucun défi familial',
              style: PharmaConnectTypography.heading3,
            ),
            SizedBox(height: 8),
            Text(
              'Créez votre premier défi pour motiver votre famille',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.challenges.length,
      itemBuilder: (context, index) {
        final challenge = provider.challenges[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FamilyChallengeCard(
            challenge: challenge,
            onTap: () => context.push('/family/challenges/${challenge.id}'),
          ),
        );
      },
    );
  }
}
