import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../providers/delivery_provider.dart';
import '../widgets/delivery_status_badge.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DeliveryProvider>();
      provider.loadDeliveries();
      provider.loadAvailableDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final driverId = 'drv_001'; // Simulé : le driver connecté

    final myDeliveries = provider.deliveries
        .where((d) => d.driver?.id == driverId)
        .toList();

    final activeDeliveries = myDeliveries
        .where((d) => d.isActive || d.status == DeliveryStatus.arrived)
        .toList();

    final completedDeliveries = myDeliveries
        .where((d) => d.status == DeliveryStatus.delivered)
        .toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
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
                    'Tableau de bord livreur',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Gérez vos livraisons en temps réel',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),

            // Statistiques
            Row(
              children: [
                _buildStatCard(
                  label: 'En cours',
                  value: '${activeDeliveries.length}',
                  color: PharmaConnectColors.accentPurple,
                  icon: Icons.delivery_dining,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  label: 'Terminées',
                  value: '${completedDeliveries.length}',
                  color: PharmaConnectColors.accentGreen,
                  icon: Icons.check_circle,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  label: 'Gain du jour',
                  value: CurrencyFormatter.format(
                    completedDeliveries.length * 5000,
                  ),
                  color: PharmaConnectColors.accentCyan,
                  icon: Icons.attach_money,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Livraisons actives
            const Text(
              'Livraisons en cours',
              style: PharmaConnectTypography.heading3,
            ),
            const SizedBox(height: 12),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : activeDeliveries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune livraison en cours',
                            style: PharmaConnectTypography.heading3,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'En attente de nouvelles missions',
                            style: PharmaConnectTypography.body2,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: activeDeliveries.length,
                      itemBuilder: (context, index) {
                        final delivery = activeDeliveries[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildDeliveryCard(delivery),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: PharmaConnectTypography.micro,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: PharmaConnectTypography.kpiMedium.copyWith(
                color: color,
                fontSize: 20,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Delivery delivery) {
    final isReady = delivery.status == DeliveryStatus.arrived;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  delivery.patientName,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DeliveryStatusBadge(status: delivery.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            delivery.deliveryAddress,
            style: PharmaConnectTypography.body2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                delivery.estimatedArrival,
                style: PharmaConnectTypography.micro,
              ),
              const Spacer(),
              if (delivery.isExpress) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: PharmaConnectColors.accentOrange.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '⚡ Express',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: PharmaConnectColors.accentOrange,
                    ),
                  ),
                ),
              ],
              if (delivery.isColdChainRequired) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: PharmaConnectColors.accentCyan.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '❄️ Froid',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: PharmaConnectColors.accentCyan,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isReady) ...[
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Marquer comme livrée',
              icon: Icons.check_circle,
              onPressed: () {
                _showCompletionDialog(context, delivery);
              },
            ),
          ] else if (delivery.status == DeliveryStatus.inProgress) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                // Simuler l'arrivée
                context.read<DeliveryProvider>().markAsArrived(delivery.id);
              },
              icon: const Icon(Icons.location_on),
              label: const Text('Je suis arrivé'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ] else if (delivery.status == DeliveryStatus.preparing) ...[
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Démarrer la livraison',
              icon: Icons.play_arrow,
              onPressed: () async {
                await context.read<DeliveryProvider>().startDelivery(
                  delivery.id,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Livraison démarrée !'),
                      backgroundColor: PharmaConnectColors.accentGreen,
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, Delivery delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Confirmer la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Confirmez-vous la livraison ?',
              style: PharmaConnectTypography.body1,
            ),
            const SizedBox(height: 8),
            const Text(
              'Veuillez vous assurer que le client a bien reçu son colis.',
              style: PharmaConnectTypography.body2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<DeliveryProvider>()
                  .completeDelivery(
                    deliveryId: delivery.id,
                    confirmationCode:
                        'CONF${DateTime.now().millisecondsSinceEpoch}',
                    recipientName: delivery.patientName,
                  );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Livraison confirmée !'),
                    backgroundColor: PharmaConnectColors.accentGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentGreen,
              foregroundColor: PharmaConnectColors.textPrimary,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
