import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../providers/eprescription_provider.dart';
import '../widgets/eprescription_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class EPrescriptionListScreen extends StatefulWidget {
  final bool isDoctor;
  final bool isPharmacy;

  const EPrescriptionListScreen({
    super.key,
    this.isDoctor = false,
    this.isPharmacy = false,
  });

  @override
  State<EPrescriptionListScreen> createState() =>
      _EPrescriptionListScreenState();
}

class _EPrescriptionListScreenState extends State<EPrescriptionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrescriptions();
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
          _selectedStatus = 'sent';
          break;
        case 2:
          _selectedStatus = 'validated';
          break;
      }
    });
    _loadPrescriptions();
  }

  void _loadPrescriptions() {
    final userId = SupabaseService().currentUser?.id;
    if (userId != null) {
      context.read<EPrescriptionProvider>().loadPrescriptions(
        patientId: widget.isDoctor || widget.isPharmacy ? null : userId,
        doctorId: widget.isDoctor ? userId : null,
        pharmacyId: widget.isPharmacy ? userId : null,
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
    final provider = context.watch<EPrescriptionProvider>();

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
                    'e-Prescriptions',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Prescriptions électroniques sécurisées',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (widget.isDoctor) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/eprescription/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle prescription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.primary,
                      foregroundColor: context.palette.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Toutes'),
                Tab(text: 'Envoyées'),
                Tab(text: 'Validées'),
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

  Widget _buildContent(EPrescriptionProvider provider) {
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
                _loadPrescriptions();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            const SizedBox(height: 16),
            Text('Aucune e-prescription', style: context.text.heading3),
            const SizedBox(height: 8),
            Text(
              widget.isDoctor
                  ? 'Créez votre première prescription électronique'
                  : widget.isPharmacy
                  ? 'Aucune prescription reçue'
                  : 'Vous n\'avez pas encore de prescriptions électroniques',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.prescriptions.length,
      itemBuilder: (context, index) {
        final prescription = provider.prescriptions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EPrescriptionCard(
            prescription: prescription,
            onTap: () => context.push('/eprescription/${prescription.id}'),
          ),
        );
      },
    );
  }
}
