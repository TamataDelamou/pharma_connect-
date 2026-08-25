import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/payment_provider.dart';
import '../models/transaction_status.dart';
import '../../../core/utils/currency_formatter.dart';

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen> {
  bool _isReconciling = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    final pendingTransactions = provider.transactions
        .where((t) => t.status == TransactionStatus.pending)
        .toList();

    final completedTransactions = provider.transactions
        .where(
          (t) =>
              t.status == TransactionStatus.completed ||
              t.status == TransactionStatus.processing,
        )
        .toList();

    final totalPending = pendingTransactions.fold(
      0,
      (sum, t) => sum + t.finalAmount,
    );
    final totalCompleted = completedTransactions.fold(
      0,
      (sum, t) => sum + t.finalAmount,
    );

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
                    'Réconciliation',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifiez et réconciliez vos transactions',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),

            if (provider.isLoading) ...[
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ] else ...[
              // Résumé
              Row(
                children: [
                  _buildSummaryCard(
                    label: 'En attente',
                    value: pendingTransactions.length.toString(),
                    amount: totalPending,
                    color: PharmaConnectColors.accentOrange,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    label: 'À réconcilier',
                    value: completedTransactions.length.toString(),
                    amount: totalCompleted,
                    color: PharmaConnectColors.accentCyan,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    label: 'Total',
                    value: provider.transactions.length.toString(),
                    amount: totalPending + totalCompleted,
                    color: PharmaConnectColors.accentGreen,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Transactions en attente
              const Text(
                'Transactions en attente de réconciliation',
                style: PharmaConnectTypography.heading3,
              ),
              const SizedBox(height: 8),

              Expanded(
                child: pendingTransactions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: PharmaConnectColors.accentGreen,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Toutes les transactions sont réconciliées',
                              style: PharmaConnectTypography.body2,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pendingTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = pendingTransactions[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${transaction.id}',
                                        style: PharmaConnectTypography.body1
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        transaction.pharmacyName ?? 'Pharmacie',
                                        style: PharmaConnectTypography.body2,
                                      ),
                                      Text(
                                        '${CurrencyFormatter.format(transaction.finalAmount)} • ${_formatDate(transaction.createdAt)}',
                                        style: PharmaConnectTypography.micro,
                                      ),
                                    ],
                                  ),
                                ),
                                PrimaryButton(
                                  label: 'Réconcilier',
                                  onPressed: _isReconciling
                                      ? null
                                      : () async {
                                          setState(() => _isReconciling = true);
                                          final success = await provider
                                              .confirmPayment(transaction.id);
                                          setState(
                                            () => _isReconciling = false,
                                          );
                                          if (success && context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Transaction réconciliée',
                                                ),
                                                backgroundColor:
                                                    PharmaConnectColors
                                                        .accentGreen,
                                              ),
                                            );
                                          }
                                        },
                                  width: 120,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required int amount,
    required Color color,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: PharmaConnectTypography.micro),
            Text(
              value,
              style: PharmaConnectTypography.kpiMedium.copyWith(
                color: color,
                fontSize: 20,
              ),
            ),
            Text(
              CurrencyFormatter.format(amount),
              style: PharmaConnectTypography.micro,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
