import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/search_provider.dart';
import '../widgets/pharmacy_list_tile.dart';
import '../../../core/theme/palette.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadProductAvailability(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final availability = search.selectedProductAvailability;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Détail du produit',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 24),
            // Contenu
            Expanded(
              child: availability == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fiche produit
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: context.palette.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.medication,
                                        color: context.palette.primary,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            availability.product.name,
                                            style: context.text.heading3,
                                          ),
                                          Text(
                                            availability.product.genericName,
                                            style: context.text.body2,
                                          ),
                                          Text(
                                            '${availability.product.dosage} • ${availability.product.form}',
                                            style: context.text.micro,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(color: context.palette.veil(0.12)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      availability.product.manufacturer,
                                      Icons.business,
                                      context.palette.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      availability.product.isGeneric
                                          ? 'Générique'
                                          : 'Princeps',
                                      Icons.local_pharmacy,
                                      availability.product.isGeneric
                                          ? context.palette.secondary
                                          : context.palette.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      availability
                                              .product
                                              .isPrescriptionRequired
                                          ? 'Sur ordonnance'
                                          : 'Libre',
                                      Icons.description,
                                      availability
                                              .product
                                              .isPrescriptionRequired
                                          ? context.palette.warning
                                          : context.palette.success,
                                    ),
                                  ],
                                ),
                                if (availability.product.description !=
                                    null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    availability.product.description!,
                                    style: context.text.body2,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Disponibilité par pharmacie
                          Text(
                            'Disponibilité en pharmacie',
                            style: context.text.heading3,
                          ),
                          const SizedBox(height: 8),
                          if (availability.hasAvailableStock) ...[
                            Text(
                              '${availability.availableCount} pharmacie(s) disponible(s)',
                              style: context.text.body2,
                            ),
                          ] else ...[
                            Text(
                              'Aucune disponibilité pour le moment',
                              style: context.text.body2.copyWith(
                                color: context.palette.danger,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Liste des pharmacies
                          ...availability.pharmacyStocks.map((stock) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PharmacyListTile(
                                stock: stock,
                                onTap: stock.isAvailable
                                    ? () {
                                        // TODO: Naviguer vers la réservation
                                      }
                                    : null,
                              ),
                            );
                          }),
                          if (availability.hasAvailableStock) ...[
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: 'Réserver ce produit',
                              icon: Icons.shopping_cart,
                              onPressed: () {
                                // TODO: Naviguer vers la réservation
                              },
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

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
