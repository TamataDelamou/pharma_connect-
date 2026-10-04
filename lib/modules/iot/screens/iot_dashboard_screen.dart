import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/iot_provider.dart';
import '../widgets/device_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class IotDashboardScreen extends StatefulWidget {
  const IotDashboardScreen({super.key});

  @override
  State<IotDashboardScreen> createState() => _IotDashboardScreenState();
}

class _IotDashboardScreenState extends State<IotDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDevices();
    });
  }

  void _onTabChanged() {
    final index = _tabController.index;
    setState(() {
      switch (index) {
        case 0:
          _selectedStatus = null;
          break;
        case 1:
          _selectedStatus = 'active';
          break;
        case 2:
          _selectedStatus = 'offline';
          break;
      }
    });
    _loadDevices();
  }

  // Audit Module 21 (IOT), Étape 2 (30/08/2026), C99 : transmettait l'id du
  // compte utilisateur connecté (`SupabaseService().currentUser?.id`) comme
  // `pharmacyId`, alors que `iot_devices.pharmacy_id` référence
  // `public.pharmacies(id)` — deux identifiants différents. Aucun appareil
  // réel n'était donc jamais retrouvé pour un pharmacien légitime. Corrigé
  // en utilisant `AuthProvider.pharmacyId` (résolu depuis `profiles.pharmacy_id`
  // au chargement du profil), le mécanisme déjà établi et réutilisé dans le
  // reste du projet (stock, réservations, marketplace).
  void _loadDevices() {
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId != null) {
      context.read<IotProvider>().loadDevices(
        pharmacyId: pharmacyId,
        status: _selectedStatus,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IotProvider>();

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
                    '📡 Objets connectés',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Surveillez vos capteurs et équipements',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                ElevatedButton.icon(
                  onPressed: () => context.push('/iot/device/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Tous'),
                Tab(text: 'Actifs'),
                Tab(text: 'Hors ligne'),
              ],
              labelColor: context.palette.primary,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: context.palette.primary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 16),

            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(IotProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.palette.danger),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: context.text.body2.copyWith(color: context.palette.danger),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                _loadDevices();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucun appareil connecté', style: context.text.heading3),
            SizedBox(height: 8),
            Text(
              'Ajoutez votre premier capteur ou équipement',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.devices.length,
      itemBuilder: (context, index) {
        final device = provider.devices[index];
        return DeviceCard(
          device: device,
          onTap: () => context.push('/iot/device/${device.id}'),
        );
      },
    );
  }
}
