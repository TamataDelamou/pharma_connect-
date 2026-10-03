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
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import '../providers/marketplace_provider.dart';
import '../models/b2b_order.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceProvider>().loadOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final order = provider.selectedOrder;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (order == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Commande introuvable',
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        ),
      );
    }

    // Audit Module 13 (B2B, 29/08/2026) : même correctif d'identifiant que
    // offer_detail_screen.dart — `order.buyerPharmacyId`/`sellerPharmacyId`
    // sont des ids d'OFFICINE, jamais égaux à l'id UTILISATEUR connecté.
    // Toutes les actions de transition de statut de cet écran (soumettre,
    // confirmer, expédier, recevoir...) étaient donc inaccessibles à tout
    // le monde. Corrigé via `AuthProvider.pharmacyId`.
    final pharmacyId = context.watch<AuthProvider>().pharmacyId;
    final isBuyer = pharmacyId != null && order.buyerPharmacyId == pharmacyId;
    final isSeller = pharmacyId != null && order.sellerPharmacyId == pharmacyId;

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
                      'Détail de la commande',
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
                    color: _statusColor(order.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${order.statusIcon} ${order.statusLabel}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(order.status),
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
                    // Order info
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Acheteur',
                            order.buyerName ?? order.buyerPharmacyId,
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Vendeur',
                            order.sellerName ?? order.sellerPharmacyId,
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow('Date', _formatDate(order.createdAt)),
                          if (order.submittedAt != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Soumise le',
                              _formatDate(order.submittedAt!),
                            ),
                          ],
                          if (order.confirmedAt != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Confirmée le',
                              _formatDate(order.confirmedAt!),
                            ),
                          ],
                          if (order.deliveredAt != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Livrée le',
                              _formatDate(order.deliveredAt!),
                            ),
                          ],
                          if (order.notes != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Notes', order.notes!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items
                    if (order.items != null && order.items!.isNotEmpty) ...[
                      const Text(
                        'Articles',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...order.items!.map((item) {
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
                                      '${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                                      style: PharmaConnectTypography.micro,
                                    ),
                                  ],
                                ),
                              ),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              CurrencyFormatter.format(order.totalAmount),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: PharmaConnectColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Actions
                    if (order.status == 'draft' && isBuyer) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Soumettre la commande',
                              icon: Icons.send,
                              onPressed: () async {
                                final success = await provider
                                    .updateOrderStatus(order.id, 'submitted');
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Commande soumise'),
                                      backgroundColor:
                                          PharmaConnectColors.accentGreen,
                                    ),
                                  );
                                  provider.loadOrder(order.id);
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
                                    .updateOrderStatus(order.id, 'cancelled');
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Commande annulée'),
                                    ),
                                  );
                                  provider.loadOrder(order.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (order.status == 'submitted' && isSeller) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Confirmer la commande',
                              icon: Icons.check_circle,
                              onPressed: () async {
                                final success = await provider
                                    .updateOrderStatus(order.id, 'confirmed');
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Commande confirmée'),
                                      backgroundColor:
                                          PharmaConnectColors.accentGreen,
                                    ),
                                  );
                                  provider.loadOrder(order.id);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Refuser',
                              icon: Icons.close,
                              onPressed: () async {
                                final success = await provider
                                    .updateOrderStatus(order.id, 'cancelled');
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Commande refusée'),
                                    ),
                                  );
                                  provider.loadOrder(order.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (order.status == 'confirmed' && isSeller) ...[
                      PrimaryButton(
                        label: 'Marquer comme expédiée',
                        icon: Icons.local_shipping,
                        onPressed: () async {
                          final success = await provider.updateOrderStatus(
                            order.id,
                            'shipped',
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Commande expédiée'),
                                backgroundColor: PharmaConnectColors.accentCyan,
                              ),
                            );
                            provider.loadOrder(order.id);
                          }
                        },
                      ),
                    ],

                    if (order.status == 'shipped' && isBuyer) ...[
                      PrimaryButton(
                        label: 'Marquer comme reçue',
                        icon: Icons.done_all,
                        onPressed: () async {
                          final success = await provider.updateOrderStatus(
                            order.id,
                            'delivered',
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Commande reçue'),
                                backgroundColor:
                                    PharmaConnectColors.accentGreen,
                              ),
                            );
                            provider.loadOrder(order.id);
                          }
                        },
                      ),
                    ],

                    if (order.status == 'delivered') ...[
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
                                'Commande livrée le ${_formatDate(order.deliveredAt ?? DateTime.now())}',
                                style: TextStyle(
                                  color: PharmaConnectColors.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (order.status == 'cancelled') ...[
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
                                'Commande annulée',
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
            width: 100,
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
      case 'draft':
        return PharmaConnectColors.textSecondary;
      case 'submitted':
        return PharmaConnectColors.accentCyan;
      case 'confirmed':
        return PharmaConnectColors.accentGreen;
      case 'shipped':
        return PharmaConnectColors.accentPurple;
      case 'delivered':
        return PharmaConnectColors.accentGreen;
      case 'cancelled':
        return PharmaConnectColors.accentRed;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }
}
