import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../models/pos_sale.dart';
import '../providers/pos_provider.dart';
import '../widgets/refund_confirmation_dialog.dart';

class POSReceiptScreen extends StatefulWidget {
  final String? saleId;

  const POSReceiptScreen({super.key, this.saleId});

  @override
  State<POSReceiptScreen> createState() => _POSReceiptScreenState();
}

class _POSReceiptScreenState extends State<POSReceiptScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.saleId != null) {
        context.read<POSProvider>().loadSale(widget.saleId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final sale = provider.currentSale;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (sale == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Vente introuvable',
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
                      '🧾 Reçu de vente',
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
                    // Receipt card
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'PHARMACONNECT',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: PharmaConnectColors.accentCyan,
                                  ),
                                ),
                                Text(
                                  'Reçu #${sale.saleNumber}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: PharmaConnectColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 8),
                          _buildInfoRow('Date', _formatDate(sale.createdAt)),
                          _buildInfoRow(
                            'Caissier',
                            sale.cashierName ?? sale.cashierId,
                          ),
                          if (sale.patientName != null)
                            _buildInfoRow('Patient', sale.patientName!),
                          if (sale.paymentMethod != null)
                            _buildInfoRow('Paiement', sale.paymentLabel),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 8),

                          // Items
                          if (sale.items != null) ...[
                            ...sale.items!.map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item.productName,
                                        style: PharmaConnectTypography.body2,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                                      style: PharmaConnectTypography.micro,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      CurrencyFormatter.format(item.totalPrice),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: PharmaConnectColors.accentCyan,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(color: Colors.white12),
                          ],

                          // Totals
                          _buildTotalRow('Total', sale.totalAmount),
                          if (sale.discountAmount > 0)
                            _buildTotalRow(
                              'Remise',
                              -sale.discountAmount,
                              color: PharmaConnectColors.accentPurple,
                            ),
                          _buildTotalRow('TVA', sale.taxAmount),
                          const Divider(color: Colors.white12),
                          _buildTotalRow(
                            'À payer',
                            sale.finalAmount,
                            isTotal: true,
                          ),

                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Merci de votre visite !',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: PharmaConnectColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: provider.isPrinting
                                ? 'Impression...'
                                : '🖨️ Imprimer',
                            isLoading: provider.isPrinting,
                            onPressed: () async {
                              final success = await provider.printReceipt();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reçu imprimé avec succès'),
                                    backgroundColor:
                                        PharmaConnectColors.accentGreen,
                                  ),
                                );
                              } else if (context.mounted &&
                                  provider.error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(provider.error!),
                                    backgroundColor:
                                        PharmaConnectColors.accentRed,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SecondaryButton(
                            label: '📤 Partager',
                            onPressed: () {
                              // Share receipt
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SecondaryButton(
                            label: '🔄 Rembourser',
                            onPressed: sale.isCompleted
                                ? () => _confirmRefund(context, sale)
                                : null,
                          ),
                        ),
                      ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: PharmaConnectTypography.micro),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body2)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    int amount, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: isTotal
                ? PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  )
                : PharmaConnectTypography.body2,
          ),
          const Spacer(),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color:
                  color ??
                  (isTotal ? PharmaConnectColors.accentCyan : Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmRefund(BuildContext context, POSSale sale) async {
    // C204 : motif et destination du stock choisis dans le dialogue commun.
    final decision = await showRefundConfirmationDialog(
      context,
      saleNumber: sale.saleNumber,
      finalAmount: sale.finalAmount,
    );
    if (decision == null || !context.mounted) return;

    final provider = context.read<POSProvider>();
    final success = await provider.refundSale(
      sale.id,
      reason: decision.reason,
      stockDisposition: decision.stockDisposition,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Vente remboursée avec succès'
              : provider.error ?? 'Remboursement refusé',
        ),
        backgroundColor: success
            ? PharmaConnectColors.accentGreen
            : PharmaConnectColors.accentRed,
      ),
    );
    if (success) context.pop();
  }
}
