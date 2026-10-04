import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../../search/services/location_service.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../providers/delivery_provider.dart';
import '../widgets/delivery_status_badge.dart';
import '../../../core/theme/palette.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final LocationService _locationService = LocationService();
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  // Bug corrigé (audit Module 7, 29/08/2026) : cet écran utilisait un
  // driverId en dur ('drv_001') au lieu de résoudre la fiche delivery_drivers
  // réellement rattachée à AuthProvider.userId — même défaut que 'ph_1'
  // (Module 6)/'admin' (Module 4). De plus, la liste des courses était
  // chargée non filtrée (`loadDeliveries()`) puis filtrée côté client sur cet
  // id en dur — ce qui, RLS correctement scopée désormais, ne remontait de
  // toute façon plus rien pour un livreur : aucune policy de lecture
  // "livreur" n'existait avant ce module (voir le rapport d'audit).
  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    if (userId == null) return;
    final provider = context.read<DeliveryProvider>();
    await provider.loadMyDriverProfile(userId);
    final driverId = provider.myDriverProfile?.id;
    if (driverId == null) return;
    await provider.loadDeliveriesForDriver(driverId);
    provider.loadAvailableDrivers();
    _startLocationUpdates(driverId);
  }

  /// Amélioration UX + fonctionnalité (audit Module 7, 29/08/2026) :
  /// DeliveryService.updateLocation/updateDriverLocation existaient déjà
  /// mais n'avaient aucun appelant — la carte de suivi patient
  /// (delivery_tracking_screen.dart) affichait donc toujours la position
  /// figée au moment de la planification, jamais la position réelle du
  /// livreur, malgré "Suivi en temps réel de la course" (fonctionnalité
  /// clé du cahier). Repose sur LocationService (déjà utilisé par le
  /// module recherche), interrogée en avant-plan à intervalle régulier tant
  /// que l'écran est ouvert — ce n'est pas un vrai suivi en tâche de fond
  /// (aucune infrastructure de ce type dans le projet, voir le registre des
  /// écarts), mais une amélioration réelle par rapport à l'absence totale
  /// de mise à jour de position qui existait avant ce module.
  void _startLocationUpdates(String driverId) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      if (!mounted) return;
      final provider = context.read<DeliveryProvider>();
      final active = provider.deliveries
          .where((d) => d.status == DeliveryStatus.inProgress)
          .toList();
      if (active.isEmpty) return;
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;
      await provider.updateMyLocation(
        driverId,
        position.latitude,
        position.longitude,
      );
      for (final delivery in active) {
        await provider.updateDeliveryLocation(
          delivery.id,
          position.latitude,
          position.longitude,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<DeliveryProvider>();

    // Aucun contrôle d'accès n'existait sur cet écran (audit Module 7) —
    // même correctif que pharmacy_queue_screen.dart (Module 6).
    if (auth.effectiveRole != UserRole.livreur) {
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
                  'Réservé aux comptes livreur.',
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
    if (!provider.isLoading && provider.myDriverProfile == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Aucune fiche livreur associée à ce compte.',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final activeDeliveries = provider.deliveries
        .where((d) => d.isActive || d.status == DeliveryStatus.arrived)
        .toList();

    final completedDeliveries = provider.deliveries
        .where((d) => d.status == DeliveryStatus.delivered)
        .toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
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
                      'Tableau de bord livreur',
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
              'Gérez vos livraisons en temps réel',
              style: context.text.body2,
            ),
            // Bannière hors-ligne (audit Module 7, 29/08/2026) : même patron
            // que les autres écrans déjà audités — n'affiche jamais ce
            // message par-dessus des courses vides si le cache local est
            // lui aussi vide (provider.deliveries reste alors vraiment vide,
            // et le message d'état vide générique ci-dessous suffit).
            if (provider.isOffline && provider.deliveries.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.palette.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.palette.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: context.palette.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error ??
                            'Hors connexion — dernières courses synchronisées affichées.',
                        style: context.text.body2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Statistiques
            Row(
              children: [
                _buildStatCard(
                  label: 'En cours',
                  value: '${activeDeliveries.length}',
                  color: context.palette.secondary,
                  icon: Icons.delivery_dining,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  label: 'Terminées',
                  value: '${completedDeliveries.length}',
                  color: context.palette.success,
                  icon: Icons.check_circle,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  label: 'Gain du jour',
                  value: CurrencyFormatter.format(
                    completedDeliveries.length * 5000,
                  ),
                  color: context.palette.primary,
                  icon: Icons.attach_money,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Livraisons actives
            Text('Livraisons en cours', style: context.text.heading3),
            const SizedBox(height: 12),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : activeDeliveries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: context.palette.veil(0.24),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune livraison en cours',
                            style: context.text.heading3,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'En attente de nouvelles missions',
                            style: context.text.body2,
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
                    style: context.text.micro,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: context.text.kpiMedium.copyWith(
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
    final palette = context.palette;
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
                  style: context.text.body1.copyWith(
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
            style: context.text.body2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer, size: 14, color: context.palette.textSecondary),
              const SizedBox(width: 4),
              Text(delivery.estimatedArrival, style: context.text.micro),
              const Spacer(),
              if (delivery.isExpress) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '⚡ Express',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.palette.warning,
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
                    color: context.palette.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '❄️ Froid',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.palette.primary,
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
                side: BorderSide(color: context.palette.veil(0.24)),
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
                    SnackBar(
                      content: Text('Livraison démarrée !'),
                      backgroundColor: palette.success,
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

  // RG-LIV-02 (audit Module 7, 29/08/2026) : cette boîte de dialogue
  // fabriquait auparavant un faux code ('CONF' + timestamp) jamais vérifié
  // par personne — la "preuve de remise" réussissait donc toujours, même
  // sans que le colis ait réellement été remis. Désormais le livreur doit
  // saisir le code à 6 chiffres communiqué par le patient (généré à la
  // planification, voir Delivery.confirmationCode) ; le code est vérifié
  // côté serveur dans DeliveryService.completeDelivery et un code erroné
  // remonte une erreur explicite plutôt que de réussir silencieusement.
  void _showCompletionDialog(BuildContext context, Delivery delivery) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          String? errorText;
          return AlertDialog(
            backgroundColor: context.palette.background,
            title: const Text('Confirmer la livraison'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demandez au patient le code de remise à 6 chiffres qui lui '
                  'a été communiqué et saisissez-le ci-dessous.',
                  style: context.text.body2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  style: context.text.body1,
                  decoration: InputDecoration(
                    labelText: 'Code de remise',
                    counterText: '',
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final code = codeController.text.trim();
                  if (code.isEmpty) {
                    setState(() => errorText = 'Code requis.');
                    return;
                  }
                  final provider = context.read<DeliveryProvider>();
                  final success = await provider.completeDelivery(
                    deliveryId: delivery.id,
                    enteredConfirmationCode: code,
                    recipientName: delivery.patientName,
                  );
                  if (!dialogContext.mounted) return;
                  if (success) {
                    Navigator.pop(dialogContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Livraison confirmée !'),
                          backgroundColor: context.palette.success,
                        ),
                      );
                    }
                  } else {
                    setState(
                      () => errorText =
                          provider.error ?? 'Code de remise incorrect.',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.success,
                  foregroundColor: context.palette.onPrimary,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      ),
    );
  }
}
