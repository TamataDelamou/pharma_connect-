import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../providers/triage_provider.dart';
import '../models/triage_status.dart';
import '../widgets/triage_patient_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class TriageListScreen extends StatefulWidget {
  final bool isNurse;

  const TriageListScreen({super.key, this.isNurse = false});

  @override
  State<TriageListScreen> createState() => _TriageListScreenState();
}

class _TriageListScreenState extends State<TriageListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TriageStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatients();
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
          _selectedStatus = TriageStatus.waiting;
          break;
        case 2:
          _selectedStatus = TriageStatus.inAssessment;
          break;
      }
    });
    _loadPatients();
  }

  void _loadPatients() {
    final userId = SupabaseService().currentUser?.id;
    if (userId != null) {
      context.read<TriageProvider>().loadPatients(
        status: _selectedStatus,
        nurseId: widget.isNurse ? userId : null,
        patientId: widget.isNurse ? null : userId,
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
    final provider = context.watch<TriageProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Triage', style: context.text.heading1),
                      SizedBox(height: 4),
                      Text(
                        'Gestion des urgences et orientation des patients',
                        style: context.text.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                if (widget.isNurse) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/triage/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau patient'),
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
                Tab(text: 'Tous'),
                Tab(text: 'En attente'),
                Tab(text: 'En évaluation'),
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

  Widget _buildContent(TriageProvider provider) {
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
                _loadPatients();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emergency_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucun patient en triage', style: context.text.heading3),
            SizedBox(height: 8),
            Text(
              widget.isNurse
                  ? 'Aucun patient en attente de triage'
                  : 'Vous n\'avez aucun dossier de triage',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.patients.length,
      itemBuilder: (context, index) {
        final patient = provider.patients[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TriagePatientCard(
            patient: patient,
            onTap: () => context.push('/triage/${patient.id}'),
          ),
        );
      },
    );
  }
}
