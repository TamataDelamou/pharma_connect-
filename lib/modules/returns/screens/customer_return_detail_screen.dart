import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/returns_provider.dart';
import '../models/customer_return.dart';

class CustomerReturnDetailScreen extends StatefulWidget {
  final String returnId;

  const CustomerReturnDetailScreen({super.key, required this.returnId});

  @override
  State<CustomerReturnDetailScreen> createState() =>
      _CustomerReturnDetailScreenState();
}

class _CustomerReturnDetailScreenState
    extends State<CustomerReturnDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReturnsProvider>().loadCustomerReturn(widget.returnId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReturnsProvider>();
    final returnData = provider.selectedCustomerReturn;

    if (provider.isLoading && returnData?.id != widget.returnId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (returnData == null || returnData.id != widget.returnId) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Retour introuvable',
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
                Expanded(
                  child: Text(
                    returnData.returnNumber,
                    style: PharmaConnectTypography.heading2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const KernelBadge(),
              ],
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(returnData.status),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Client',
                            returnData.customerName ??
                                returnData.customerId ??
                                'Non renseigné',
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Date',
                            _formatDate(returnData.returnDate),
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Motif',
                            returnData.reasonName ??
                                returnData.reasonText ??
                                'Non précisé',
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Montant',
                            CurrencyFormatter.format(returnData.totalAmount),
                          ),
                          if (returnData.refundAmount != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Remboursé',
                              CurrencyFormatter.format(
                                returnData.refundAmount!,
                              ),
                            ),
                          ],
                          if (returnData.notes != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Notes', returnData.notes!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (returnData.status == ReturnStatus.pending) ...[
                      const Text(
                        'Actions',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(
                                context,
                                ReturnStatus.approved,
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text('Approuver'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    PharmaConnectColors.accentGreen,
                                foregroundColor:
                                    PharmaConnectColors.textOnAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(
                                context,
                                ReturnStatus.rejected,
                              ),
                              icon: const Icon(Icons.close),
                              label: const Text('Rejeter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PharmaConnectColors.accentRed,
                                foregroundColor:
                                    PharmaConnectColors.textOnAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (returnData.status ==
                        ReturnStatus.approved) ...[
                      ElevatedButton.icon(
                        onPressed: () =>
                            _updateStatus(context, ReturnStatus.completed),
                        icon: const Icon(Icons.done_all),
                        label: const Text('Marquer comme terminé'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PharmaConnectColors.accentCyan,
                          foregroundColor: PharmaConnectColors.textOnAccent,
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

  Future<void> _updateStatus(
    BuildContext context,
    ReturnStatus newStatus,
  ) async {
    final provider = context.read<ReturnsProvider>();
    final success = await provider.updateCustomerReturnStatus(
      widget.returnId,
      newStatus,
    );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour : ${newStatus.label}'),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erreur lors de la mise à jour'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: PharmaConnectTypography.label),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body1)),
        ],
      ),
    );
  }

  Color _statusColor(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.pending:
        return const Color(0xFFF59E0B);
      case ReturnStatus.approved:
        return const Color(0xFF10B981);
      case ReturnStatus.rejected:
        return const Color(0xFFEF4444);
      case ReturnStatus.completed:
        return const Color(0xFF00D9FF);
      case ReturnStatus.cancelled:
        return const Color(0xFF9CA3AF);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
