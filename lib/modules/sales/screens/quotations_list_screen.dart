import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/sales_provider.dart';
import '../models/quotation.dart';
import '../../auth/providers/auth_provider.dart';

class QuotationsListScreen extends StatefulWidget {
  const QuotationsListScreen({super.key});

  @override
  State<QuotationsListScreen> createState() => _QuotationsListScreenState();
}

class _QuotationsListScreenState extends State<QuotationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuotations());
  }

  void _loadQuotations() {
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) return;
    context.read<SalesProvider>().loadQuotations(pharmacyId: pharmacyId);
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyId = context.watch<AuthProvider>().pharmacyId;
    if (pharmacyId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Aucune officine rattachée à ce compte pharmacien.',
            style: PharmaConnectTypography.body2,
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
                      '📄 Devis',
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
                _loadQuotations();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.quotations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Aucun devis', style: PharmaConnectTypography.heading3),
            SizedBox(height: 8),
            Text(
              'Les devis émis apparaîtront ici',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.quotations.length,
      itemBuilder: (context, index) {
        final quotation = provider.quotations[index];
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
                    color: _statusColor(quotation.status),
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
                            quotation.quotationNumber,
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
                                quotation.status,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              quotation.status.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _statusColor(quotation.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        quotation.customerName ?? 'Client',
                        style: PharmaConnectTypography.body2,
                      ),
                      Text(
                        CurrencyFormatter.format(quotation.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: PharmaConnectColors.accentCyan,
                        ),
                      ),
                      if (quotation.validUntil != null)
                        Text(
                          'Valable jusqu\'au ${_formatDate(quotation.validUntil!)}',
                          style: PharmaConnectTypography.body2.copyWith(
                            fontSize: 12,
                            color: PharmaConnectColors.textSecondary,
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

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  Color _statusColor(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return PharmaConnectColors.textSecondary;
      case QuotationStatus.sent:
        return PharmaConnectColors.accentCyan;
      case QuotationStatus.accepted:
        return PharmaConnectColors.accentGreen;
      case QuotationStatus.rejected:
        return PharmaConnectColors.accentRed;
      case QuotationStatus.expired:
        return PharmaConnectColors.accentOrange;
    }
  }
}
