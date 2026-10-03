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
import '../models/b2b_offer.dart';
// Audit Module 13 (B2B, 29/08/2026) : `import '../models/b2b_order_item.dart'`
// (fichier inexistant — B2BOrderItem est déclarée dans b2b_order.dart, pas
// dans un fichier séparé) supprimé — erreur de compilation bloquante pour
// tout l'écran. B2BOrderItem, utilisée plus bas dans `_createOrder`, est
// déjà visible via l'import de b2b_order.dart ci-dessous.
import '../models/b2b_order.dart';
import '../models/b2b_negotiation.dart';

class OfferDetailScreen extends StatefulWidget {
  final String offerId;

  const OfferDetailScreen({super.key, required this.offerId});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  final _negotiationController = TextEditingController();
  final _quantityController = TextEditingController();
  int _proposedPrice = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceProvider>().loadOffer(widget.offerId);
    });
  }

  @override
  void dispose() {
    _negotiationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final offer = provider.selectedOffer;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (offer == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Offre introuvable',
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        ),
      );
    }

    // Audit Module 13 (B2B, 29/08/2026) : comparait `offer.sellerPharmacyId`
    // (un id d'OFFICINE) à `SupabaseService().currentUser?.id` (l'id de
    // l'UTILISATEUR connecté) — les deux ne coïncident jamais (même bug que
    // les policies RLS et que marketplace_home_screen.dart, voir leurs
    // commentaires). `isSeller` était donc toujours faux et `isBuyer`
    // toujours vrai pour tout utilisateur connecté, y compris le vendeur
    // lui-même consultant sa propre offre. Corrigé via
    // `AuthProvider.pharmacyId`.
    final pharmacyId = context.watch<AuthProvider>().pharmacyId;
    final isSeller = pharmacyId != null && offer.sellerPharmacyId == pharmacyId;
    final isBuyer = pharmacyId != null && !isSeller;

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
                      'Détail de l\'offre',
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
                    color: offer.isActive
                        ? PharmaConnectColors.accentGreen.withValues(
                            alpha: 0.15,
                          )
                        : PharmaConnectColors.accentRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    offer.isActive ? 'Active' : offer.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: offer.isActive
                          ? PharmaConnectColors.accentGreen
                          : PharmaConnectColors.accentRed,
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
                    // Product info
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.productName,
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            offer.sellerName ?? offer.sellerPharmacyId,
                            style: PharmaConnectTypography.body2,
                          ),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Prix',
                            CurrencyFormatter.format(offer.price),
                          ),
                          _buildInfoRow(
                            'Quantité disponible',
                            '${offer.quantity} ${offer.unit}',
                          ),
                          _buildInfoRow(
                            'Commande minimum',
                            '${offer.minOrderQuantity} ${offer.unit}',
                          ),
                          if (offer.expiryDate != null)
                            _buildInfoRow(
                              'Expire le',
                              _formatDate(offer.expiryDate!),
                            ),
                          if (offer.description != null)
                            _buildInfoRow('Description', offer.description!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Negotiations
                    if (provider.negotiations.isNotEmpty) ...[
                      const Text(
                        'Négociations',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...provider.negotiations.map((neg) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _negotiationStatusColor(
                                neg.status,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '💰 ${CurrencyFormatter.format(neg.proposedPrice)}',
                                      style: PharmaConnectTypography.body1
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (neg.proposedQuantity != null)
                                      Text(
                                        'Qté: ${neg.proposedQuantity}',
                                        style: PharmaConnectTypography.micro,
                                      ),
                                    Text(
                                      neg.statusLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _negotiationStatusColor(
                                          neg.status,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (neg.status == 'pending' && isSeller) ...[
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check,
                                        color: PharmaConnectColors.accentGreen,
                                      ),
                                      onPressed: () async {
                                        final updated = neg.copyWith(
                                          status: 'accepted',
                                        );
                                        await context
                                            .read<MarketplaceProvider>()
                                            .updateNegotiation(updated);
                                        provider.loadOffer(widget.offerId);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: PharmaConnectColors.accentRed,
                                      ),
                                      onPressed: () async {
                                        final updated = neg.copyWith(
                                          status: 'rejected',
                                        );
                                        await context
                                            .read<MarketplaceProvider>()
                                            .updateNegotiation(updated);
                                        provider.loadOffer(widget.offerId);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.swap_horiz,
                                        color: PharmaConnectColors.accentCyan,
                                      ),
                                      onPressed: () =>
                                          _showCounterOfferDialog(neg),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),

                    // Actions
                    if (offer.isActive) ...[
                      if (isSeller) ...[
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'Modifier',
                                icon: Icons.edit,
                                // Audit Module 13 (B2B, 29/08/2026) : ce
                                // bouton était un no-op (`onPressed: () {}`,
                                // jamais implémenté). Corrigé — voir
                                // OfferCreateScreen.existingOffer.
                                onPressed: () => context.push(
                                  '/marketplace/offer/edit/${offer.id}',
                                  extra: offer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SecondaryButton(
                                label: 'Retirer',
                                icon: Icons.close,
                                onPressed: () async {
                                  final updated = offer.copyWith(
                                    status: 'cancelled',
                                  );
                                  await context
                                      .read<MarketplaceProvider>()
                                      .saveOffer(updated);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Offre retirée'),
                                      ),
                                    );
                                    provider.loadOffer(widget.offerId);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (isBuyer) ...[
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'Acheter maintenant',
                                icon: Icons.shopping_cart,
                                onPressed: () => _createOrder(context, offer),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SecondaryButton(
                                label: 'Négocier',
                                icon: Icons.chat,
                                onPressed: () =>
                                    _showNegotiationDialog(context, offer),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],

                    if (!offer.isActive) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.textSecondary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              offer.status == 'expired'
                                  ? Icons.timer_off
                                  : Icons.block,
                              color: PharmaConnectColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cette offre est ${offer.statusLabel.toLowerCase()}',
                                style: PharmaConnectTypography.body2,
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
            width: 120,
            child: Text(label, style: PharmaConnectTypography.label),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body1)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _negotiationStatusColor(String status) {
    switch (status) {
      case 'pending':
        return PharmaConnectColors.accentOrange;
      case 'accepted':
        return PharmaConnectColors.accentGreen;
      case 'rejected':
        return PharmaConnectColors.accentRed;
      case 'countered':
        return PharmaConnectColors.accentCyan;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }

  Future<void> _createOrder(BuildContext context, B2BOffer offer) async {
    final quantity = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Commander'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Produit: ${offer.productName}'),
            Text('Prix unitaire: ${CurrencyFormatter.format(offer.price)}'),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantité (min ${offer.minOrderQuantity})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(_quantityController.text);
              if (qty != null && qty >= offer.minOrderQuantity) {
                Navigator.pop(ctx, qty);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Quantité minimum: ${offer.minOrderQuantity}',
                    ),
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (quantity == null) return;

    // Audit Module 13 (B2B, 29/08/2026) : `buyerPharmacyId` doit être un id
    // d'officine — corrigé de `SupabaseService().currentUser?.id` vers
    // `AuthProvider.pharmacyId` (même bug que plus haut dans ce fichier).
    if (!context.mounted) return;
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) return;

    final order = B2BOrder(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      buyerPharmacyId: pharmacyId,
      sellerPharmacyId: offer.sellerPharmacyId,
      status: 'draft',
      totalAmount: offer.price * quantity,
      notes: 'Commande depuis l\'offre: ${offer.productName}',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      items: [
        B2BOrderItem(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          orderId: '',
          offerId: offer.id,
          productName: offer.productName,
          quantity: quantity,
          unitPrice: offer.price,
          totalPrice: offer.price * quantity,
          createdAt: DateTime.now().toUtc(),
        ),
      ],
    );

    final success = await context.read<MarketplaceProvider>().saveOrder(order);
    if (success && context.mounted) {
      context.push(
        '/marketplace/order/${context.read<MarketplaceProvider>().selectedOrder?.id}',
      );
    }
  }

  void _showNegotiationDialog(BuildContext context, B2BOffer offer) {
    final priceController = TextEditingController(text: offer.price.toString());
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Négocier le prix'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Offre actuelle: ${CurrencyFormatter.format(offer.price)}'),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Prix proposé',
                border: OutlineInputBorder(),
                prefixText: 'GNF ',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantité (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = int.tryParse(priceController.text);
              if (price == null || price <= 0) return;
              final qty = int.tryParse(qtyController.text);

              // Audit Module 13 (B2B, 29/08/2026) : même correctif
              // `AuthProvider.pharmacyId` qu'au-dessus.
              final pharmacyId = context.read<AuthProvider>().pharmacyId;
              if (pharmacyId == null) return;

              final negotiation = B2BNegotiation(
                id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                offerId: offer.id,
                buyerPharmacyId: pharmacyId,
                proposedPrice: price,
                proposedQuantity: qty,
                status: 'pending',
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
              );

              final success = await context
                  .read<MarketplaceProvider>()
                  .createNegotiation(negotiation);
              Navigator.pop(ctx);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Négociation envoyée'),
                    backgroundColor: PharmaConnectColors.accentGreen,
                  ),
                );
                // Phase 4 (module marketplace) : `provider` référençait une
                // variable locale à build() inaccessible depuis cette
                // méthode séparée - défaut de compilation, jamais détecté
                // faute de compilateur exécuté à la clôture du Module 13/B2B.
                // Corrigé sur le même patron que createNegotiation() ci-dessus.
                context.read<MarketplaceProvider>().loadOffer(widget.offerId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showCounterOfferDialog(B2BNegotiation neg) {
    final priceController = TextEditingController(
      text: neg.proposedPrice.toString(),
    );
    final qtyController = TextEditingController(
      text: neg.proposedQuantity?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Contre-offre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nouveau prix',
                border: OutlineInputBorder(),
                prefixText: 'GNF ',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nouvelle quantité',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = int.tryParse(priceController.text);
              if (price == null || price <= 0) return;
              final qty = int.tryParse(qtyController.text);

              final updated = neg.copyWith(
                status: 'countered',
                counterOfferPrice: price,
                counterOfferQuantity: qty,
                updatedAt: DateTime.now().toUtc(),
              );

              final success = await context
                  .read<MarketplaceProvider>()
                  .updateNegotiation(updated);
              Navigator.pop(ctx);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contre-offre envoyée'),
                    backgroundColor: PharmaConnectColors.accentCyan,
                  ),
                );
                // Phase 4 (module marketplace) : même correctif que la
                // méthode _showNegotiationDialog ci-dessus.
                context.read<MarketplaceProvider>().loadOffer(widget.offerId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
