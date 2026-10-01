import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/delivery.dart';
import '../models/delivery_driver.dart';
import '../models/delivery_status.dart';
import '../providers/delivery_provider.dart';
import '../widgets/delivery_status_badge.dart';

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
    final provider = context.read<DeliveryProvider>();
    final driver = await showModalBottomSheet<DeliveryDriver>(
      context: context,
      backgroundColor: PharmaConnectColors.primaryDeep,
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
            backgroundColor: ok
                ? PharmaConnectColors.accentGreen
                : PharmaConnectColors.accentRed,
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
                const Icon(Icons.lock_outline, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'Réservé aux pharmaciens de l\'officine.',
                  style: PharmaConnectTypography.body2,
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
                    'Planification des livraisons',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${scheduled.length} livraison(s) à assigner',
              style: PharmaConnectTypography.body2,
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
                            style: PharmaConnectTypography.body2.copyWith(
                              color: PharmaConnectColors.accentRed,
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
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune livraison à planifier',
                            style: PharmaConnectTypography.body2,
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
                                        style: PharmaConnectTypography.body1
                                            .copyWith(
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
                                  style: PharmaConnectTypography.body2,
                                ),
                                Text(
                                  'Prévue le ${delivery.scheduledAt.day}/${delivery.scheduledAt.month} '
                                  'à ${delivery.scheduledAt.hour.toString().padLeft(2, '0')}h'
                                  '${delivery.scheduledAt.minute.toString().padLeft(2, '0')}',
                                  style: PharmaConnectTypography.micro,
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
                                        side: const BorderSide(
                                          color: PharmaConnectColors.accentCyan,
                                        ),
                                        foregroundColor:
                                            PharmaConnectColors.accentCyan,
                                      ),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        size: 16,
                                        color: PharmaConnectColors.accentGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${delivery.driver!.name} • ${delivery.driver!.vehicleType ?? 'véhicule'}',
                                          style: PharmaConnectTypography.body2,
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => context
                                            .read<DeliveryProvider>()
                                            .startDelivery(delivery.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              PharmaConnectColors.accentCyan,
                                          foregroundColor:
                                              PharmaConnectColors.textOnAccent,
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
            const Text(
              'Choisir un livreur',
              style: PharmaConnectTypography.heading3,
            ),
            if (requiresColdChain) ...[
              const SizedBox(height: 4),
              const Text(
                'Livraison chaîne du froid : seuls les livreurs certifiés sont proposés',
                style: PharmaConnectTypography.micro,
              ),
            ],
            const SizedBox(height: 16),
            if (eligible.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucun livreur disponible pour le moment',
                  style: PharmaConnectTypography.body2,
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
                        backgroundColor: PharmaConnectColors.accentCyan
                            .withValues(alpha: 0.2),
                        child: Text(
                          driver.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: PharmaConnectColors.accentCyan,
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
                          ? const Icon(
                              Icons.ac_unit,
                              color: PharmaConnectColors.accentCyan,
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
