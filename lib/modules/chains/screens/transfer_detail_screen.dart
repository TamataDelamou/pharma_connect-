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
import '../../auth/providers/auth_provider.dart';
import '../providers/chain_provider.dart';
import '../models/stock_transfer.dart';

class TransferDetailScreen extends StatefulWidget {
  final String transferId;

  const TransferDetailScreen({super.key, required this.transferId});

  @override
  State<TransferDetailScreen> createState() => _TransferDetailScreenState();
}

class _TransferDetailScreenState extends State<TransferDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChainProvider>().loadTransfer(widget.transferId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChainProvider>();
    final transfer = provider.selectedTransfer;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (transfer == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Transfert introuvable',
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        ),
      );
    }

    // Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-6 : ces deux
    // comparaisons opposaient un identifiant d'officine
    // (`fromPharmacyId`/`toPharmacyId`) à un identifiant UTILISATEUR
    // (`SupabaseService().currentUser?.id`) — structurellement (quasiment)
    // toujours faux, même famille que PRE-6 (Module 25) et que le motif
    // RLS lui-même (CHN-5). Corrigé en comparant à la pharmacie de
    // rattachement du compte connecté (`AuthProvider.pharmacyId`), déjà
    // exposée côté client depuis l'audit du Module 1 (AUT).
    final pharmacyId = context.watch<AuthProvider>().pharmacyId;
    final isFromPharmacy =
        pharmacyId != null && transfer.fromPharmacyId == pharmacyId;
    final isToPharmacy =
        pharmacyId != null && transfer.toPharmacyId == pharmacyId;
    final canManage = isFromPharmacy || isToPharmacy;

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
                      'Détail du transfert',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(
                      transfer.status,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transfer.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(transfer.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'De',
                            transfer.fromPharmacyName ??
                                transfer.fromPharmacyId,
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'À',
                            transfer.toPharmacyName ?? transfer.toPharmacyId,
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Date',
                            _formatDate(transfer.transferDate),
                          ),
                          if (transfer.receivedDate != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Reçu le',
                              _formatDate(transfer.receivedDate!),
                            ),
                          ],
                          if (transfer.notes != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Notes', transfer.notes!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items
                    if (transfer.items != null &&
                        transfer.items!.isNotEmpty) ...[
                      const Text(
                        'Articles',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...transfer.items!.map((item) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.medication,
                                color: PharmaConnectColors.accentCyan,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: PharmaConnectTypography.body2
                                          .copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    Text(
                                      'Qté: ${item.quantity}',
                                      style: PharmaConnectTypography.micro,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),

                    // Actions
                    if (transfer.status == 'pending' && canManage) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Approuver',
                              icon: Icons.check_circle,
                              onPressed: () async {
                                final success = await provider
                                    .updateTransferStatus(
                                      transfer.id,
                                      'approved',
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Transfert approuvé'),
                                      backgroundColor:
                                          PharmaConnectColors.accentGreen,
                                    ),
                                  );
                                  provider.loadTransfer(transfer.id);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Annuler',
                              icon: Icons.close,
                              onPressed: () async {
                                final success = await provider
                                    .updateTransferStatus(
                                      transfer.id,
                                      'cancelled',
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Transfert annulé'),
                                    ),
                                  );
                                  provider.loadTransfer(transfer.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (transfer.status == 'approved' && isFromPharmacy) ...[
                      PrimaryButton(
                        label: 'Marquer comme expédié',
                        icon: Icons.local_shipping,
                        onPressed: () async {
                          final success = await provider.updateTransferStatus(
                            transfer.id,
                            'in_transit',
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transfert en transit'),
                                backgroundColor: PharmaConnectColors.accentCyan,
                              ),
                            );
                            provider.loadTransfer(transfer.id);
                          }
                        },
                      ),
                    ],

                    if (transfer.status == 'in_transit' && isToPharmacy) ...[
                      PrimaryButton(
                        label: 'Marquer comme reçu',
                        icon: Icons.done_all,
                        onPressed: () async {
                          final success = await provider.updateTransferStatus(
                            transfer.id,
                            'received',
                            receivedDate: DateTime.now(),
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transfert reçu'),
                                backgroundColor:
                                    PharmaConnectColors.accentGreen,
                              ),
                            );
                            provider.loadTransfer(transfer.id);
                          }
                        },
                      ),
                    ],

                    if (transfer.status == 'received') ...[
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
                                'Transfert reçu le ${_formatDate(transfer.receivedDate ?? DateTime.now())}',
                                style: TextStyle(
                                  color: PharmaConnectColors.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (transfer.status == 'cancelled') ...[
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
                              Icons.block,
                              color: PharmaConnectColors.accentRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Transfert annulé',
                                style: TextStyle(
                                  color: PharmaConnectColors.accentRed,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: PharmaConnectTypography.label),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body1)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return PharmaConnectColors.accentOrange;
      case 'approved':
        return PharmaConnectColors.accentCyan;
      case 'in_transit':
        return PharmaConnectColors.accentPurple;
      case 'received':
        return PharmaConnectColors.accentGreen;
      case 'cancelled':
        return PharmaConnectColors.accentRed;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }
}
