import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../providers/delivery_provider.dart';
import '../widgets/delivery_status_badge.dart';
import '../widgets/delivery_timeline.dart';
import '../widgets/driver_info_card.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String? deliveryId;

  const DeliveryTrackingScreen({super.key, this.deliveryId});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DeliveryProvider>();
      if (widget.deliveryId != null) {
        provider.loadDelivery(widget.deliveryId!);
      } else {
        // Audit Module 7 (29/08/2026) : loadDeliveries() (non filtré) ne
        // bénéficie d'aucun repli hors-ligne — on passe par
        // loadDeliveriesForPatient, qui suit le même patron déjà audité que
        // loadPatientReservations (Module 6), pour que l'écran continue à
        // afficher la livraison active en cours même sans connexion.
        final userId = context.read<AuthProvider>().userId;
        if (userId != null) {
          provider.loadDeliveriesForPatient(userId);
        } else {
          provider.loadDeliveries();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final delivery = widget.deliveryId != null
        ? provider.selectedDelivery
        : provider.activeDeliveries.isNotEmpty
        ? provider.activeDeliveries.first
        : null;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (delivery == null) {
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
                      'Suivi des livraisons',
                      style: PharmaConnectTypography.heading2,
                    ),
                  ),
                  const KernelBadge(),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 64,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune livraison en cours',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vos livraisons apparaîtront ici',
                        style: PharmaConnectTypography.body2,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Voir l\'historique',
                        onPressed: () => context.go('/deliveries/history'),
                        width: 200,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                Expanded(
                  child: Text(
                    'Suivi de livraison',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('#${delivery.id}', style: PharmaConnectTypography.body2),
                const Spacer(),
                DeliveryStatusBadge(status: delivery.status),
              ],
            ),
            if (provider.isOffline) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PharmaConnectColors.accentOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: PharmaConnectColors.accentOrange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: PharmaConnectColors.accentOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error ??
                            'Hors connexion — dernière position connue affichée.',
                        style: PharmaConnectTypography.body2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Carte
            Expanded(
              flex: 2,
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        delivery.latitude ?? 9.5095,
                        delivery.longitude ?? -13.7122,
                      ),
                      initialZoom: 13,
                      interactionOptions: const InteractionOptions(
                        enableMultiFingerGestureRace: true,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.pharmaconnect.app',
                      ),
                      // Marqueur du livreur (si en cours)
                      if (delivery.status == DeliveryStatus.inProgress &&
                          delivery.driver != null) ...[
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                delivery.latitude ?? 9.5095,
                                delivery.longitude ?? -13.7122,
                              ),
                              width: 48,
                              height: 48,
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 48 + 20 * _pulseController.value,
                                        height:
                                            48 + 20 * _pulseController.value,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: PharmaConnectColors
                                              .accentPurple
                                              .withValues(
                                                alpha:
                                                    0.3 -
                                                    0.25 *
                                                        _pulseController.value,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              PharmaConnectColors.accentPurple,
                                        ),
                                        child: const Icon(
                                          Icons.delivery_dining,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Marqueur de destination
                      if (delivery.status != DeliveryStatus.delivered) ...[
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                (delivery.latitude ?? 9.5095) + 0.002,
                                (delivery.longitude ?? -13.7122) + 0.002,
                              ),
                              width: 32,
                              height: 32,
                              child: const Icon(
                                Icons.location_on,
                                color: PharmaConnectColors.accentRed,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informations de suivi
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Timeline
                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: DeliveryTimeline(delivery: delivery),
                    ),
                    const SizedBox(height: 8),

                    // Informations livreur
                    if (delivery.driver != null) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: DriverInfoCard(driver: delivery.driver!),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Code de remise (RG-LIV-02, audit Module 7, 29/08/2026) :
                    // communiqué de vive voix par le patient au livreur, qui
                    // le saisit pour clôturer la livraison — voir
                    // DeliveryService.completeDelivery.
                    if (delivery.confirmationCode != null &&
                        (delivery.status == DeliveryStatus.inProgress ||
                            delivery.status == DeliveryStatus.arrived)) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.vpn_key,
                              color: PharmaConnectColors.accentCyan,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Votre code de remise',
                                    style: PharmaConnectTypography.body2,
                                  ),
                                  Text(
                                    delivery.confirmationCode!,
                                    style: PharmaConnectTypography.heading2
                                        .copyWith(letterSpacing: 4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Actions
                    if (delivery.status == DeliveryStatus.arrived) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'Confirmer la réception',
                                icon: Icons.check_circle,
                                onPressed: () {
                                  _showConfirmationDialog(context, delivery);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (delivery.status == DeliveryStatus.inProgress) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer,
                              color: PharmaConnectColors.accentCyan,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Arrivée estimée : ${delivery.estimatedArrival}',
                                style: PharmaConnectTypography.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: PharmaConnectColors.accentCyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (delivery.canBeCancelled) ...[
                      const SizedBox(height: 8),
                      TertiaryButton(
                        label: 'Annuler la livraison',
                        icon: Icons.cancel,
                        onPressed: () => _showCancelDialog(context, delivery),
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

  // RG-LIV-02 (audit Module 7, 29/08/2026) : ce dialogue fabriquait un faux
  // code jamais vérifié. Le patient confirme désormais avec SON PROPRE code
  // de remise (delivery.confirmationCode, déjà affiché au-dessus sur cet
  // écran) — auto-rempli, puisque le patient le connaît déjà et n'a rien à
  // saisir de nouveau. Limite documentée au registre : une confirmation
  // faite par le patient sur son propre appareil n'est pas une preuve
  // indépendante à deux parties comme lorsque c'est le livreur qui saisit
  // le code communiqué par le patient (driver_dashboard_screen.dart).
  void _showConfirmationDialog(BuildContext context, Delivery delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Confirmer la réception'),
        content: const Text(
          'Avez-vous bien reçu votre colis en bon état ?',
          style: PharmaConnectTypography.body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non, problème'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<DeliveryProvider>();
              final success = await provider.completeDelivery(
                deliveryId: delivery.id,
                enteredConfirmationCode: delivery.confirmationCode,
              );
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Livraison confirmée avec succès !'),
                    backgroundColor: PharmaConnectColors.accentGreen,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.error ??
                          'Impossible de confirmer la réception.',
                    ),
                    backgroundColor: PharmaConnectColors.accentRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentGreen,
              foregroundColor: PharmaConnectColors.textPrimary,
            ),
            child: const Text('Oui, confirmer'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Delivery delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Annuler la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir annuler cette livraison ?',
              style: PharmaConnectTypography.body1,
            ),
            const SizedBox(height: 8),
            Text(
              'Cette action est irréversible.',
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<DeliveryProvider>()
                  .cancelDelivery(
                    delivery.id,
                    reason: 'Annulation par le client',
                  );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Livraison annulée'),
                    backgroundColor: PharmaConnectColors.accentRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentRed,
              foregroundColor: PharmaConnectColors.textPrimary,
            ),
            child: const Text('Confirmer l\'annulation'),
          ),
        ],
      ),
    );
  }
}
