import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../providers/homecare_provider.dart';
import '../models/homecare_status.dart';
import '../widgets/intervention_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class HomecareListScreen extends StatefulWidget {
  final bool asProfessional;

  const HomecareListScreen({super.key, this.asProfessional = false});

  @override
  State<HomecareListScreen> createState() => _HomecareListScreenState();
}

class _HomecareListScreenState extends State<HomecareListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HomecareStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInterventions();
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
          _selectedStatus = HomecareStatus.pending;
          break;
        case 2:
          _selectedStatus = HomecareStatus.confirmed;
          break;
      }
    });
    _loadInterventions();
  }

  void _loadInterventions() {
    final userId = SupabaseService().currentUser?.id;
    if (userId != null) {
      context.read<HomecareProvider>().loadInterventions(
        userId: userId,
        asProfessional: widget.asProfessional,
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
    final provider = context.watch<HomecareProvider>();

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
                    'Soins à domicile',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gérez vos interventions à domicile',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (!widget.asProfessional) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/homecare/book'),
                    icon: const Icon(Icons.add),
                    label: const Text('Demander une intervention'),
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
                Tab(text: 'En attente'),
                Tab(text: 'Confirmées'),
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

  Widget _buildContent(HomecareProvider provider) {
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
                _loadInterventions();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.interventions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_repair_service_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucune intervention', style: context.text.heading3),
            SizedBox(height: 8),
            Text(
              widget.asProfessional
                  ? 'Aucune intervention ne vous a été assignée'
                  : 'Demandez une intervention à domicile',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.interventions.length,
      itemBuilder: (context, index) {
        final intervention = provider.interventions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InterventionCard(
            intervention: intervention,
            onTap: () => context.push('/homecare/${intervention.id}'),
          ),
        );
      },
    );
  }
}
