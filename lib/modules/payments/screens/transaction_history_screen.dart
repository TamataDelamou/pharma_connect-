import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/transaction_list_tile.dart';
import '../models/transaction_status.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  TransactionStatus? _selectedStatus;
  String _searchQuery = '';

  // Bug corrigé (audit Module 8, 29/08/2026) : 'patient_123' en dur —
  // même défaut que wallet_screen.dart/payment_screen.dart dans ce module.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) return;
      context.read<PaymentProvider>().loadTransactions(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    final filteredTransactions = provider.transactions.where((t) {
      if (_selectedStatus != null && t.status != _selectedStatus) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return t.id.toLowerCase().contains(query) ||
            (t.pharmacyName?.toLowerCase().contains(query) ?? false) ||
            (t.transactionReference?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();

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
                const Expanded(
                  child: Text(
                    'Historique des transactions',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Consultez toutes vos transactions passées',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 16),

            // Barre de recherche
            GlassInput(
              label: '',
              hint: 'Rechercher une transaction...',
              prefixIcon: Icons.search,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 12),

            // Filtres par statut
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip(null, 'Toutes'),
                  ...TransactionStatus.values.map(
                    (status) => _buildStatusChip(status, status.label),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Liste
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTransactions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Aucune transaction trouvée',
                            style: PharmaConnectTypography.body2,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return TransactionListTile(
                          transaction: transaction,
                          onTap: () {
                            context.push('/transactions/${transaction.id}');
                          },
                          showStatus: true,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TransactionStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) =>
            setState(() => _selectedStatus = isSelected ? null : status),
        selectedColor: PharmaConnectColors.accentCyan.withValues(alpha: 0.2),
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: isSelected ? PharmaConnectColors.accentCyan : Colors.white24,
        ),
      ),
    );
  }
}
