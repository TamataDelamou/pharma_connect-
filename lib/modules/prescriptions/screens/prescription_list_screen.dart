import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/prescription_status.dart';
import '../providers/prescription_provider.dart';
import '../widgets/prescription_card.dart';

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
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ordonnances',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gérez vos ordonnances numériques',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/prescriptions/upload'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filtres par onglet
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Toutes'),
                Tab(text: 'En attente'),
                Tab(text: 'Validées'),
                Tab(text: 'Dispensées'),
              ],
              labelColor: PharmaConnectColors.accentCyan,
              unselectedLabelColor: PharmaConnectColors.textSecondary,
              indicatorColor: PharmaConnectColors.accentCyan,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 24),

            // Liste des ordonnances
            Expanded(
              child: provider.prescriptions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune ordonnance',
                            style: PharmaConnectTypography.heading2,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Importez votre première ordonnance numérique',
                            style: PharmaConnectTypography.body2,
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
