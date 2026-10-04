import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/sales_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      final pharmacyId = context.read<AuthProvider>().pharmacyId;
      if (pharmacyId == null) return;
      if (userId != null) {
        context.read<SalesProvider>().loadCustomers(pharmacyId: pharmacyId);
      }
    });
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

    final provider = context.watch<SalesProvider>();

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
                      '👤 Clients',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                // C232 : écran absent — « Nouveau » client
                // (/sales/customer/new, route désactivée hors cahier) masqué.
              ],
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final userId = SupabaseService().currentUser?.id;
                final pharmacyId = context.read<AuthProvider>().pharmacyId;
                if (pharmacyId == null) return;
                if (userId != null) {
                  provider.loadCustomers(pharmacyId: pharmacyId, search: value);
                }
              },
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(child: Text(provider.error!))
                  : provider.customers.isEmpty
                  ? Center(
                      child: Text('Aucun client', style: context.text.body2),
                    )
                  : ListView.builder(
                      itemCount: provider.customers.length,
                      itemBuilder: (context, index) {
                        final customer = provider.customers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            // C232 : écran absent — ouverture de la fiche
                            // client (/sales/customer/:id) masquée.
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: context.palette.primary
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    customer.firstName[0],
                                    style: TextStyle(
                                      color: context.palette.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.fullName,
                                        style: context.text.body1.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        customer.code,
                                        style: context.text.mono,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      customer.balanceLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: customer.balance > 0
                                            ? context.palette.success
                                            : customer.balance < 0
                                            ? context.palette.danger
                                            : context.palette.textSecondary,
                                      ),
                                    ),
                                    if (customer.phone != null)
                                      Text(
                                        customer.phone!,
                                        style: context.text.micro,
                                      ),
                                  ],
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: context.palette.veil(0.24),
                                ),
                              ],
                            ),
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
