import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/delivery.dart';
import '../providers/delivery_provider.dart';
import '../widgets/delivery_card.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  // Audit Module 7 (29/08/2026) : loadDeliveries() (non filtré, sans repli
  // hors-ligne) remplacé par loadDeliveriesForPatient — même patron déjà
  // audité que ReservationProvider.loadPatientReservations (Module 6),
  // avec mise en cache local des livraisons du patient.
  void _load() {
    final userId = context.read<AuthProvider>().userId;
    final provider = context.read<DeliveryProvider>();
    if (userId != null) {
      provider.loadDeliveriesForPatient(userId);
    } else {
      provider.loadDeliveries();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();

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
                    'Mes livraisons',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'En cours'),
                Tab(text: 'Passées'),
              ],
              labelColor: PharmaConnectColors.accentCyan,
              unselectedLabelColor: PharmaConnectColors.textSecondary,
              indicatorColor: PharmaConnectColors.accentCyan,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            // Bannière hors-ligne (audit Module 7, 29/08/2026) : mêmes règles
            // que les autres écrans déjà audités — ne s'affiche que quand
            // des livraisons issues du cache sont réellement montrées, pour
            // ne jamais masquer la liste avec un message d'erreur bloquant
            // (bug corrigé ci-dessous : provider.error != null seul cachait
            // la liste même quand des données mises en cache existaient).
            if (provider.isOffline && provider.deliveries.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 12),
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
                            'Hors connexion — dernières livraisons synchronisées affichées.',
                        style: PharmaConnectTypography.body2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null && provider.deliveries.isEmpty
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
                            onPressed: _load,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(context, provider.activeDeliveries),
                        _buildList(context, provider.pastDeliveries),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Delivery> deliveries) {
    if (deliveries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Aucune livraison', style: PharmaConnectTypography.body2),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DeliveryCard(
            delivery: delivery,
            onTap: () => context.push('/deliveries/tracking/${delivery.id}'),
          ),
        );
      },
    );
  }
}
