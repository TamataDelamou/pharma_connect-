import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/payment_provider.dart';
import '../models/payment_method.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadTransaction(widget.transactionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final transaction = provider.selectedTransaction;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.error != null || transaction == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.error ?? 'Transaction introuvable',
                style: PharmaConnectTypography.body2.copyWith(
                  color: PharmaConnectColors.accentRed,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
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
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
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
                      'Détail de la transaction',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: transaction.statusColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  transaction.method == PaymentMethod.gsgWallet
                                      ? Icons.account_balance_wallet
                                      : transaction.method.isMobileMoney
                                      ? Icons.phone_android
                                      : transaction.method ==
                                            PaymentMethod.bankCard
                                      ? Icons.credit_card
                                      : Icons.payments,
                                  color: transaction.statusColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transaction.pharmacyName ?? 'Transaction',
                                      style: PharmaConnectTypography.heading3,
                                    ),
                                    Text(
                                      '#${transaction.id}',
                                      style: PharmaConnectTypography.body2,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: transaction.statusColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  transaction.statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: transaction.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 12),
                          Text(
                            CurrencyFormatter.format(transaction.finalAmount),
                            style: PharmaConnectTypography.kpiSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Détails',
                      style: PharmaConnectTypography.heading3,
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow(
                            label: 'Montant',
                            value: CurrencyFormatter.format(transaction.amount),
                          ),
                          if (transaction.fee != null && transaction.fee != 0)
                            _DetailRow(
                              label: 'Frais',
                              value: CurrencyFormatter.format(transaction.fee!),
                            ),
                          if (transaction.cashback != null &&
                              transaction.cashback != 0)
                            _DetailRow(
                              label: 'Cashback',
                              value: CurrencyFormatter.format(
                                transaction.cashback!,
                              ),
                            ),
                          _DetailRow(
                            label: 'Montant final',
                            value: CurrencyFormatter.format(
                              transaction.finalAmount,
                            ),
                            valueColor: PharmaConnectColors.accentGreen,
                          ),
                          _DetailRow(
                            label: 'Méthode',
                            value: transaction.method.label,
                          ),
                          _DetailRow(
                            label: 'Statut',
                            value: transaction.statusLabel,
                            valueColor: transaction.statusColor,
                          ),
                          if (transaction.pharmacyName != null)
                            _DetailRow(
                              label: 'Pharmacie',
                              value: transaction.pharmacyName!,
                            ),
                          _DetailRow(
                            label: 'Date',
                            value: _formatDateTime(transaction.createdAt),
                          ),
                          if (transaction.completedAt != null)
                            _DetailRow(
                              label: 'Complétée le',
                              value: _formatDateTime(transaction.completedAt!),
                            ),
                          if (transaction.refundedAt != null)
                            _DetailRow(
                              label: 'Remboursée le',
                              value: _formatDateTime(transaction.refundedAt!),
                            ),
                          if (transaction.transactionReference != null)
                            _DetailRow(
                              label: 'Référence',
                              value: transaction.transactionReference!,
                            ),
                          if (transaction.externalReference != null)
                            _DetailRow(
                              label: 'Référence externe',
                              value: transaction.externalReference!,
                            ),
                          if (transaction.notes != null &&
                              transaction.notes!.isNotEmpty)
                            _DetailRow(
                              label: 'Notes',
                              value: transaction.notes!,
                              isLast: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} à $hour:$minute';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: PharmaConnectTypography.label)),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: PharmaConnectTypography.body2.copyWith(
                color: valueColor ?? PharmaConnectColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
