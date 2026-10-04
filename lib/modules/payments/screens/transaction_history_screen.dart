import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/transaction_list_tile.dart';
import '../models/transaction_status.dart';
import '../../../core/theme/palette.dart';

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
                      'Historique des transactions',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 8),
            Text(
              'Consultez toutes vos transactions passées',
              style: context.text.body2,
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: context.palette.veil(0.24),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Aucune transaction trouvée',
                            style: context.text.body2,
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
        selectedColor: context.palette.primary.withValues(alpha: 0.2),
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: isSelected
              ? context.palette.primary
              : context.palette.veil(0.24),
        ),
      ),
    );
  }
}
