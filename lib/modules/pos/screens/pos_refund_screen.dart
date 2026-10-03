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
import '../providers/pos_provider.dart';
import '../models/pos_sale.dart';
import '../widgets/refund_confirmation_dialog.dart';

class POSRefundScreen extends StatefulWidget {
  final String? saleId;

  const POSRefundScreen({super.key, this.saleId});

  @override
  State<POSRefundScreen> createState() => _POSRefundScreenState();
}

class _POSRefundScreenState extends State<POSRefundScreen> {
  final _saleIdController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  POSSale? _selectedSale;

  @override
  void dispose() {
    _saleIdController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.saleId != null) {
      _saleIdController.text = widget.saleId!;
      _loadSale();
    }
  }

  Future<void> _loadSale() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<POSProvider>();
      await provider.loadSale(_saleIdController.text);
      _selectedSale = provider.currentSale;
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();

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
                      '🔄 Remboursement',
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
                    // Sale search
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1️⃣ Rechercher la vente',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _saleIdController,
                                  decoration: const InputDecoration(
                                    hintText: 'N° de vente ou numéro de reçu',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PrimaryButton(
                                label: 'Rechercher',
                                onPressed: _loadSale,
                                width: 100,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sale details
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentRed.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PharmaConnectColors.accentRed.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: PharmaConnectColors.accentRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!)),
                          ],
                        ),
                      )
                    else if (_selectedSale != null)
                      _buildSaleDetails(_selectedSale!),

                    const SizedBox(height: 16),

                    // Refund confirmation
                    if (_selectedSale != null &&
                        _selectedSale!.status == 'completed') ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '2️⃣ Confirmer le remboursement',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Montant à rembourser: ${CurrencyFormatter.format(_selectedSale!.finalAmount)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: PharmaConnectColors.accentOrange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _reasonController,
                              decoration: const InputDecoration(
                                hintText: 'Motif du remboursement',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: provider.isLoading
                                  ? 'Traitement...'
                                  : '🔄 Confirmer le remboursement',
                              isLoading: provider.isLoading,
                              onPressed: () => _confirmRefund(provider),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_selectedSale != null &&
                        _selectedSale!.status == 'refunded') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentGreen.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PharmaConnectColors.accentGreen.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: PharmaConnectColors.accentGreen,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cette vente a déjà été remboursée',
                                style: TextStyle(
                                  color: PharmaConnectColors.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleDetails(POSSale sale) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Vente #${sale.saleNumber}',
                style: PharmaConnectTypography.heading3,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: sale.status == 'completed'
                      ? PharmaConnectColors.accentGreen.withValues(alpha: 0.15)
                      : PharmaConnectColors.accentOrange.withValues(
                          alpha: 0.15,
                        ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sale.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sale.status == 'completed'
                        ? PharmaConnectColors.accentGreen
                        : PharmaConnectColors.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Date', _formatDate(sale.createdAt)),
          _buildInfoRow('Caissier', sale.cashierName ?? sale.cashierId),
          _buildInfoRow('Paiement', sale.paymentLabel),
          if (sale.patientName != null)
            _buildInfoRow('Patient', sale.patientName!),
          const Divider(color: Colors.white12),
          _buildInfoRow('Total', CurrencyFormatter.format(sale.finalAmount)),
          const SizedBox(height: 8),
          if (sale.items != null) ...[
            const Text('Articles:', style: PharmaConnectTypography.label),
            ...sale.items!.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: PharmaConnectTypography.micro,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: PharmaConnectTypography.body2,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.totalPrice),
                      style: PharmaConnectTypography.micro,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmRefund(POSProvider provider) async {
    final sale = _selectedSale;
    if (sale == null) return;

    // C204 : motif (prérempli depuis le champ de l'écran) et destination du
    // stock choisis dans le dialogue commun.
    final decision = await showRefundConfirmationDialog(
      context,
      saleNumber: sale.saleNumber,
      finalAmount: sale.finalAmount,
      initialReason: _reasonController.text.trim(),
    );
    if (decision == null || !mounted) return;

    final success = await provider.refundSale(
      sale.id,
      reason: decision.reason,
      stockDisposition: decision.stockDisposition,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Remboursement effectué avec succès'
              : provider.error ?? 'Remboursement refusé',
        ),
        backgroundColor: success
            ? PharmaConnectColors.accentGreen
            : PharmaConnectColors.accentRed,
      ),
    );
    if (success) {
      setState(() {
        _selectedSale = provider.currentSale;
      });
    }
  }
}
