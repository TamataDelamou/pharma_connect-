import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/preventive_alert_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class PreventiveAlertsScreen extends StatelessWidget {
  const PreventiveAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PreventiveAlertProvider>();

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
                      '🔔 Alertes préventives',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                // C232 : bouton « Configurer » (/healthrecord/alerts/new)
                // masqué, route volontairement désactivée : D33 / C95, les
                // tables preventive_alerts, preventive_alert_history,
                // health_record_vaccinations et health_actions n'existent
                // pas. À rebrancher quand ce schéma sera construit.
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Recevez des rappels personnalisés pour votre santé',
              style: context.text.body2,
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
                                provider.loadAlerts(userId);
                              }
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : provider.alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: context.palette.veil(0.24),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune alerte configurée',
                            style: context.text.heading3,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Créez des alertes pour recevoir des rappels personnalisés',
                            style: context.text.body2,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.alerts.length,
                      itemBuilder: (context, index) {
                        final alert = provider.alerts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: alert.isActive
                                        ? context.palette.primary
                                        : context.palette.textSecondary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            alert.typeLabel,
                                            style: context.text.body1.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          Switch(
                                            value: alert.isActive,
                                            onChanged: (value) {
                                              provider.toggleAlert(
                                                alert.id,
                                                value,
                                              );
                                            },
                                            activeColor:
                                                context.palette.primary,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        alert.previewMessage,
                                        style: context.text.body2,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Dernier déclenchement: ${alert.lastTriggered != null ? _formatDate(alert.lastTriggered!) : 'Jamais'}',
                                        style: context.text.micro,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: context.palette.danger,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor:
                                            context.palette.background,
                                        title: const Text(
                                          'Supprimer l\'alerte',
                                        ),
                                        content: const Text(
                                          'Êtes-vous sûr de vouloir supprimer cette alerte ?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  context.palette.danger,
                                            ),
                                            child: const Text('Supprimer'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await provider.deleteAlert(alert.id);
                                    }
                                  },
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
