import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/returns_provider.dart';
import '../models/customer_return.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class CustomerReturnsListScreen extends StatefulWidget {
  const CustomerReturnsListScreen({super.key});

  @override
  State<CustomerReturnsListScreen> createState() =>
      _CustomerReturnsListScreenState();
}

class _CustomerReturnsListScreenState extends State<CustomerReturnsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReturnStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      final pharmacyId = context.read<AuthProvider>().pharmacyId;
      if (pharmacyId == null) return;
      if (userId != null) {
        context.read<ReturnsProvider>().loadCustomerReturns(
          pharmacyId: pharmacyId,
        );
      }
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
          _selectedStatus = ReturnStatus.pending;
          break;
        case 2:
          _selectedStatus = ReturnStatus.approved;
          break;
      }
    });
    _loadReturns();
  }

  void _loadReturns() {
    final userId = SupabaseService().currentUser?.id;
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) return;
    if (userId != null) {
      context.read<ReturnsProvider>().loadCustomerReturns(
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
    final pharmacyId = context.watch<AuthProvider>().pharmacyId;
    if (pharmacyId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Aucune officine rattachée à ce compte pharmacien.',
            style: context.text.body2,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final provider = context.watch<ReturnsProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🔄 Retours clients',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                ElevatedButton.icon(
                  onPressed: () => context.push('/returns/customer/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau retour'),
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
                Tab(text: 'En attente'),
                Tab(text: 'Approuvés'),
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

  Widget _buildContent(ReturnsProvider provider) {
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
              style: context.text.body2.copyWith(color: context.palette.danger),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                _loadReturns();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.customerReturns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.undo_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucun retour client', style: context.text.heading3),
            SizedBox(height: 8),
            Text(
              'Les retours de clients apparaîtront ici',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.customerReturns.length,
      itemBuilder: (context, index) {
        final returnData = provider.customerReturns[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () => context.push('/returns/customer/${returnData.id}'),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor(returnData.status),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            returnData.returnNumber,
                            style: context.text.body1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                returnData.status,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              returnData.status.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _statusColor(returnData.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        returnData.customerName ?? 'Client',
                        style: context.text.body2,
                      ),
                      Text(
                        CurrencyFormatter.format(returnData.totalAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.palette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.pending:
        return context.palette.warning;
      case ReturnStatus.approved:
        return context.palette.success;
      case ReturnStatus.rejected:
        return context.palette.danger;
      case ReturnStatus.completed:
        return context.palette.info;
      case ReturnStatus.cancelled:
        return context.palette.textSecondary;
    }
  }
}
