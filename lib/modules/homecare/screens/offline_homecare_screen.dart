import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/offline_homecare_provider.dart';
import '../widgets/intervention_card.dart';

class OfflineHomecareScreen extends StatelessWidget {
  const OfflineHomecareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OfflineHomecareProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📡 Soins à domicile (Hors-ligne)',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Accédez à vos interventions même sans connexion',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: provider.isOffline
                        ? PharmaConnectColors.accentOrange.withValues(
                            alpha: 0.15,
                          )
                        : PharmaConnectColors.accentGreen.withValues(
                            alpha: 0.15,
                          ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: provider.isOffline
                          ? PharmaConnectColors.accentOrange.withValues(
                              alpha: 0.3,
                            )
                          : PharmaConnectColors.accentGreen.withValues(
                              alpha: 0.3,
                            ),
                    ),
                  ),
                  child: Text(
                    provider.isOffline ? '📴 Hors-ligne' : '🟢 En ligne',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: provider.isOffline
                          ? PharmaConnectColors.accentOrange
                          : PharmaConnectColors.accentGreen,
                    ),
                  ),
                ),
                if (provider.isOffline) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.sync,
                      color: PharmaConnectColors.accentCyan,
                    ),
                    onPressed: provider.isSyncing
                        ? null
                        : () => provider.syncOfflineData(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            if (provider.isSyncing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Synchronisation...'),
                    ],
                  ),
                ),
              ),

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
                                provider.loadInterventions(userId);
                              }
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : provider.interventions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_repair_service_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune intervention disponible hors-ligne',
                            style: PharmaConnectTypography.heading3,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Les interventions seront disponibles hors-ligne après la première synchronisation.',
                            style: PharmaConnectTypography.body2,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.interventions.length,
                      itemBuilder: (context, index) {
                        final intervention = provider.interventions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InterventionCard(
                            intervention: intervention,
                            onTap: () {
                              // Navigate to detail
                            },
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
}
