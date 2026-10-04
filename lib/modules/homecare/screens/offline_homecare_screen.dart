import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/offline_homecare_provider.dart';
import '../widgets/intervention_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

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
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📡 Soins à domicile (Hors-ligne)',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Accédez à vos interventions même sans connexion',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: provider.isOffline
                        ? context.palette.warning.withValues(alpha: 0.15)
                        : context.palette.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: provider.isOffline
                          ? context.palette.warning.withValues(alpha: 0.3)
                          : context.palette.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    provider.isOffline ? '📴 Hors-ligne' : '🟢 En ligne',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: provider.isOffline
                          ? context.palette.warning
                          : context.palette.success,
                    ),
                  ),
                ),
                if (provider.isOffline) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.sync, color: context.palette.primary),
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
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.palette.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
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
                                provider.loadInterventions(userId);
                              }
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : provider.interventions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_repair_service_outlined,
                            size: 64,
                            color: context.palette.veil(0.24),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune intervention disponible hors-ligne',
                            style: context.text.heading3,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Les interventions seront disponibles hors-ligne après la première synchronisation.',
                            style: context.text.body2,
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
