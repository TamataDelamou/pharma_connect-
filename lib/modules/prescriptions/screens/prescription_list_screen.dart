import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../models/prescription_status.dart';
import '../providers/prescription_provider.dart';
import '../widgets/prescription_card.dart';
import '../../../core/theme/palette.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PrescriptionStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionProvider>().loadPrescriptions();
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
          _selectedStatus = PrescriptionStatus.pending;
          break;
        case 2:
          _selectedStatus = PrescriptionStatus.validated;
          break;
        case 3:
          _selectedStatus = PrescriptionStatus.dispensed;
          break;
      }
    });
    context.read<PrescriptionProvider>().loadPrescriptions(
      status: _selectedStatus,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ordonnances',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gérez vos ordonnances numériques',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                ElevatedButton.icon(
                  onPressed: () => context.push('/prescriptions/upload'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle'),
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

            // Bandeau hors-ligne (directive standing « mode offline ») —
            // même patron visuel que stock_list_screen.dart (Module 4) pour
            // rester cohérent entre modules.
            if (provider.isOffline) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.palette.warningStrong.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.palette.warningStrong.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 18,
                      color: context.palette.warningStrong,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error ??
                            'Hors-ligne — dernière liste synchronisée affichée.',
                        style: context.text.micro,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Filtres par onglet
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Toutes'),
                Tab(text: 'En attente'),
                Tab(text: 'Validées'),
                Tab(text: 'Dispensées'),
              ],
              labelColor: context.palette.primary,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: context.palette.primary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 24),

            // Liste des ordonnances
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  // Bug corrigé (audit Module 5, 29/08/2026) : un repli
                  // hors-ligne réussi renseigne aussi `error` (message
                  // informatif, voir le bandeau ci-dessus) — sans le garde
                  // `&& provider.prescriptions.isEmpty` (même patron que
                  // stock_list_screen.dart, Module 4), cet écran plein
                  // affichait "Erreur : Hors connexion..." à la place de la
                  // liste mise en cache au lieu de la montrer.
                  : provider.error != null && provider.prescriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider.error!,
                            style: context.text.body2.copyWith(
                              color: context.palette.danger,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.loadPrescriptions(
                              status: _selectedStatus,
                            ),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : provider.prescriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: context.palette.veil(0.24),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune ordonnance',
                            style: context.text.heading2,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Importez votre première ordonnance numérique',
                            style: context.text.body2,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.prescriptions.length,
                      itemBuilder: (context, index) {
                        final prescription = provider.prescriptions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PrescriptionCard(
                            prescription: prescription,
                            onTap: () {
                              context.push('/prescriptions/${prescription.id}');
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
