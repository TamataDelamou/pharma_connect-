import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import '../providers/chain_provider.dart';
import '../widgets/group_member_tile.dart';
import '../widgets/transfer_card.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChainProvider>().loadGroup(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChainProvider>();
    final group = provider.selectedGroup;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (group == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Groupe introuvable',
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        ),
      );
    }

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
                Expanded(
                  child: Text(
                    group.name,
                    style: PharmaConnectTypography.heading2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                if (group.ownerId == SupabaseService().currentUser?.id) ...[
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/chains/group/edit/${group.id}'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmaConnectColors.accentCyan,
                      foregroundColor: PharmaConnectColors.textOnAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.push(
                      '/chains/transfer/new',
                      extra: {'groupId': group.id},
                    ),
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Transfert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmaConnectColors.accentPurple,
                      foregroundColor: PharmaConnectColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            if (group.description != null)
              Text(group.description!, style: PharmaConnectTypography.body2),
            const SizedBox(height: 8),
            Text(
              '${group.memberCount ?? 0} officines • ${group.ownerName ?? 'Propriétaire'}',
              style: PharmaConnectTypography.micro,
            ),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Membres'),
                Tab(text: 'Transferts'),
              ],
              labelColor: PharmaConnectColors.accentCyan,
              unselectedLabelColor: PharmaConnectColors.textSecondary,
              indicatorColor: PharmaConnectColors.accentCyan,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 16),

            Expanded(child: _buildTabContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(ChainProvider provider) {
    if (_tabController.index == 0) {
      // Members tab
      if (provider.members.isEmpty) {
        return const Center(
          child: Text(
            'Aucun membre dans ce groupe',
            style: PharmaConnectTypography.body2,
          ),
        );
      }
      return ListView.builder(
        itemCount: provider.members.length,
        itemBuilder: (context, index) {
          final member = provider.members[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GroupMemberTile(member: member),
          );
        },
      );
    } else {
      // Transfers tab
      if (provider.transfers.isEmpty) {
        return const Center(
          child: Text(
            'Aucun transfert dans ce groupe',
            style: PharmaConnectTypography.body2,
          ),
        );
      }
      return ListView.builder(
        itemCount: provider.transfers.length,
        itemBuilder: (context, index) {
          final transfer = provider.transfers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TransferCard(
              transfer: transfer,
              onTap: () => context.push('/chains/transfer/${transfer.id}'),
            ),
          );
        },
      );
    }
  }
}
