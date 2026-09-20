import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/support_provider.dart';
import '../widgets/ticket_card.dart';

class SupportListScreen extends StatefulWidget {
  final bool isStaff;

  const SupportListScreen({super.key, this.isStaff = false});

  @override
  State<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends State<SupportListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
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
          _selectedStatus = 'new';
          break;
        case 2:
          _selectedStatus = 'in_progress';
          break;
      }
    });
    _loadTickets();
  }

  void _loadTickets() {
    final userId = SupabaseService().currentUser?.id;
    if (userId != null) {
      context.read<SupportProvider>().loadTickets(
        patientId: widget.isStaff ? null : userId,
        assignedTo: widget.isStaff ? null : userId,
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
    final provider = context.watch<SupportProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support client',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gérez vos demandes d\'assistance',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                if (!widget.isStaff) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/support/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmaConnectColors.accentCyan,
                      foregroundColor: PharmaConnectColors.textOnAccent,
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
                Tab(text: 'Nouveaux'),
                Tab(text: 'En cours'),
              ],
              labelColor: PharmaConnectColors.accentCyan,
              unselectedLabelColor: PharmaConnectColors.textSecondary,
              indicatorColor: PharmaConnectColors.accentCyan,
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

  Widget _buildContent(SupportProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: PharmaConnectColors.accentRed,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                _loadTickets();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Aucun ticket de support',
              style: PharmaConnectTypography.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isStaff
                  ? 'Aucune demande d\'assistance en attente'
                  : 'Vous n\'avez pas encore de demandes de support',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.tickets.length,
      itemBuilder: (context, index) {
        final ticket = provider.tickets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TicketCard(
            ticket: ticket,
            onTap: () => context.push('/support/${ticket.id}'),
          ),
        );
      },
    );
  }
}
