import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/pilot/pilot_config.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/support_provider.dart';
import '../widgets/ticket_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

// C161 : `isStaff` n'est plus impose de l'exterieur (via la route) --
// determine ici depuis AuthProvider.isGsgAdmin, meme logique et meme source
// que ticket_detail_screen.dart, pour eviter que les deux ecrans divergent
// sur qui est reellement "staff".
class SupportListScreen extends StatefulWidget {
  const SupportListScreen({super.key});

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

  bool get _isStaff => context.read<AuthProvider>().isGsgAdmin;

  void _loadTickets() {
    final userId = SupabaseService().currentUser?.id;
    if (userId != null) {
      final isStaff = _isStaff;
      context.read<SupportProvider>().loadTickets(
        patientId: isStaff ? null : userId,
        assignedTo: isStaff ? null : userId,
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
    final isStaff = context.watch<AuthProvider>().isGsgAdmin;

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
                    'Support client',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gérez vos demandes d\'assistance',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                IconButton(
                  icon: Icon(
                    Icons.menu_book,
                    color: context.palette.textSecondary,
                  ),
                  tooltip: 'Base de connaissances',
                  onPressed: () => context.push('/support/knowledge-base'),
                ),
                // C239 : assistant simulé, masqué pour le pilote
                // (`PilotConfig.aiSupportBot`).
                if (PilotConfig.aiSupportBot)
                  IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: context.palette.primary,
                    ),
                    tooltip: 'Chat support',
                    onPressed: () => context.push('/support/chat'),
                  ),
                if (isStaff) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/support/staff/conversations'),
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Escalades'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.warning,
                      foregroundColor: context.palette.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
                if (!isStaff) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/support/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau ticket'),
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
                Tab(text: 'Nouveaux'),
                Tab(text: 'En cours'),
              ],
              labelColor: context.palette.primary,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: context.palette.primary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 16),

            Expanded(child: _buildContent(provider, isStaff)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SupportProvider provider, bool isStaff) {
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
            Icon(
              Icons.support_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            const SizedBox(height: 16),
            Text('Aucun ticket de support', style: context.text.heading3),
            const SizedBox(height: 8),
            Text(
              isStaff
                  ? 'Aucune demande d\'assistance en attente'
                  : 'Vous n\'avez pas encore de demandes de support',
              style: context.text.body2,
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
