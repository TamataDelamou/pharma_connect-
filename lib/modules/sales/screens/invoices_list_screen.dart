import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/sales_provider.dart';
import '../models/sales_invoice.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInvoices());
  }

  void _loadInvoices() {
    context.read<SalesProvider>().loadSalesInvoices(
      pharmacyId: 'default_pharmacy',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();

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
                    '🧾 Factures de vente',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SalesProvider provider) {
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
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                _loadInvoices();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.salesInvoices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Aucune facture de vente',
              style: PharmaConnectTypography.heading3,
            ),
            SizedBox(height: 8),
            Text(
              'Les factures émises apparaîtront ici',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.salesInvoices.length,
      itemBuilder: (context, index) {
        final invoice = provider.salesInvoices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor(invoice.displayStatus),
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
                            invoice.invoiceNumber,
                            style: PharmaConnectTypography.body1.copyWith(
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
                                invoice.displayStatus,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              invoice.displayStatus.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _statusColor(invoice.displayStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        invoice.customerName ?? 'Client',
                        style: PharmaConnectTypography.body2,
                      ),
                      Text(
                        CurrencyFormatter.format(invoice.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: PharmaConnectColors.accentCyan,
                        ),
                      ),
                      if (!invoice.isPaid)
                        Text(
                          'Reste dû : ${CurrencyFormatter.format(invoice.remainingAmount)}',
                          style: PharmaConnectTypography.body2.copyWith(
                            fontSize: 12,
                            color: invoice.isOverdue
                                ? PharmaConnectColors.accentRed
                                : PharmaConnectColors.accentOrange,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(SalesInvoiceStatus status) {
    switch (status) {
      case SalesInvoiceStatus.draft:
        return PharmaConnectColors.textSecondary;
      case SalesInvoiceStatus.sent:
        return PharmaConnectColors.accentCyan;
      case SalesInvoiceStatus.paid:
        return PharmaConnectColors.accentGreen;
      case SalesInvoiceStatus.overdue:
        return PharmaConnectColors.accentRed;
      case SalesInvoiceStatus.cancelled:
        return PharmaConnectColors.neutralDark;
    }
  }
}
