import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/delivery.dart';
import '../models/delivery_driver.dart';
import '../models/delivery_status.dart';
import '../providers/delivery_provider.dart';
import '../widgets/delivery_status_badge.dart';
import '../../../core/theme/palette.dart';

class DeliveryScheduleScreen extends StatefulWidget {
  const DeliveryScheduleScreen({super.key});

  @override
  State<DeliveryScheduleScreen> createState() => _DeliveryScheduleScreenState();
}

class _DeliveryScheduleScreenState extends State<DeliveryScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().loadDeliveries(
        status: DeliveryStatus.scheduled,
      );
      context.read<DeliveryProvider>().loadAvailableDrivers();
    });
  }

  Future<void> _assignDriver(Delivery delivery) async {
    final palette = context.palette;
    final provider = context.read<DeliveryProvider>();
    final driver = await showModalBottomSheet<DeliveryDriver>(
      context: context,
      backgroundColor: context.palette.background,
      isScrollControlled: true,
      builder: (context) => _DriverPickerSheet(
        drivers: provider.availableDrivers,
        requiresColdChain: delivery.isColdChainRequired,
      ),
    );
    if (driver != null) {
      final ok = await provider.assignDriver(delivery.id, driver.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Livreur ${driver.name} assigné'
                  : (provider.error ?? 'Échec de l\'assignation'),
            ),
            backgroundColor: ok ? palette.success : palette.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<DeliveryProvider>();
    // Aucun contrôle d'accès n'existait sur cet écran (audit Module 7,
    // 29/08/2026) : n'importe quel utilisateur authentifié pouvait ouvrir
    // /deliveries/schedule et assigner un livreur ou démarrer une course —
    // les policies RLS scopent déjà correctement les écritures côté
    // serveur (voir la migration de ce module), mais rien ne l'interdisait
    // côté UI. Même patron de correction que pharmacy_queue_screen.dart
    // (Module 6) et driver_dashboard_screen.dart (Module 7).
    final isPharmacist = auth.effectiveRole == UserRole.pharmacien;
    if (!isPharmacist) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: context.palette.veil(0.24),
                ),
                const SizedBox(height: 16),
                Text(
                  'Réservé aux pharmaciens de l\'officine.',
                  style: context.text.body2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final scheduled = provider.deliveries
        .where((d) => d.status == DeliveryStatus.scheduled)
        .toList();

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
                      'Planification des livraisons',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 8),
            Text(
              '${scheduled.length} livraison(s) à assigner',
              style: context.text.body2,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  // Bug corrigé (audit Module 7, 29/08/2026) : sans le
                  // "&& scheduled.isEmpty", une erreur survenant après un
                  // premier chargement réussi (ex. reconnexion perdue au
                  // moment d'un rafraîchissement automatique) masquait la
                  // liste déjà chargée derrière un écran d'erreur bloquant
                  // — même classe de bug que delivery_history_screen.dart.
                  : provider.error != null && scheduled.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Erreur : ${provider.error}',
                            style: context.text.body2.copyWith(
                              color: context.palette.danger,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<DeliveryProvider>().loadDeliveries(
                                  status: DeliveryStatus.scheduled,
                                ),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : scheduled.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 64,
                            color: context.palette.veil(0.24),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune livraison à planifier',
                            style: context.text.body2,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: scheduled.length,
                      itemBuilder: (context, index) {
                        final delivery = scheduled[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        delivery.patientName,
                                        style: context.text.body1.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DeliveryStatusBadge(
                                      status: delivery.status,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  delivery.deliveryAddress,
                                  style: context.text.body2,
                                ),
                                Text(
                                  'Prévue le ${delivery.scheduledAt.day}/${delivery.scheduledAt.month} '
                                  'à ${delivery.scheduledAt.hour.toString().padLeft(2, '0')}h'
                                  '${delivery.scheduledAt.minute.toString().padLeft(2, '0')}',
                                  style: context.text.micro,
                                ),
                                const SizedBox(height: 12),
                                if (delivery.driver == null)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _assignDriver(delivery),
                                      icon: const Icon(Icons.person_add_alt),
                                      label: const Text('Assigner un livreur'),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: context.palette.primary,
                                        ),
                                        foregroundColor:
                                            context.palette.primary,
                                      ),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 16,
                                        color: context.palette.success,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${delivery.driver!.name} • ${delivery.driver!.vehicleType ?? 'véhicule'}',
                                          style: context.text.body2,
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => context
                                            .read<DeliveryProvider>()
                                            .startDelivery(delivery.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              context.palette.primary,
                                          foregroundColor:
                                              context.palette.onPrimary,
                                        ),
                                        child: const Text('Démarrer'),
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
}

class _DriverPickerSheet extends StatelessWidget {
  final List<DeliveryDriver> drivers;
  final bool requiresColdChain;

  const _DriverPickerSheet({
    required this.drivers,
    required this.requiresColdChain,
  });

  @override
  Widget build(BuildContext context) {
    final eligible = drivers
        .where((d) => d.isAvailable)
        .where((d) => !requiresColdChain || d.isColdChainCertified)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choisir un livreur', style: context.text.heading3),
            if (requiresColdChain) ...[
              const SizedBox(height: 4),
              Text(
                'Livraison chaîne du froid : seuls les livreurs certifiés sont proposés',
                style: context.text.micro,
              ),
            ],
            const SizedBox(height: 16),
            if (eligible.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucun livreur disponible pour le moment',
                  style: context.text.body2,
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: eligible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final driver = eligible[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: context.palette.primary.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          driver.name[0].toUpperCase(),
                          style: TextStyle(
                            color: context.palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(driver.name),
                      subtitle: Text(
                        '${driver.vehicleType ?? 'Véhicule'} • '
                        '${driver.completedDeliveries} livraisons'
                        '${driver.rating != null ? ' • ⭐ ${driver.rating!.toStringAsFixed(1)}' : ''}',
                      ),
                      trailing: driver.isColdChainCertified
                          ? Icon(
                              Icons.ac_unit,
                              color: context.palette.primary,
                              size: 18,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(driver),
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
