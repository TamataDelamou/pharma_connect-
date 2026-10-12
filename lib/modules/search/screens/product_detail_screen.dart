import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../reservations/models/reservation_item.dart';
import '../../reservations/providers/reservation_provider.dart';
import '../models/availability_result.dart';
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

  /// C245 : ajoute le produit au panier de réservation pour l'officine
  /// touchée, puis ouvre le panier. Un panier ne porte que sur une officine :
  /// en changer vide le panier, après confirmation.
  Future<void> _reserve(
    AvailabilityResult availability,
    PharmacyStock stock,
  ) async {
    final product = availability.product;
    final reservations = context.read<ReservationProvider>();
    final pharmacy = stock.pharmacy;

    if (product.regulatoryClass == 'stupefiant' ||
        product.regulatoryClass == 'psychotrope') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} ne peut pas être réservé : présentez-vous à '
            'l\'officine avec votre ordonnance.',
          ),
        ),
      );
      return;
    }

    if (reservations.hasItemsInCart &&
        reservations.selectedPharmacyId != null &&
        reservations.selectedPharmacyId != pharmacy.id) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Changer d\'officine ?'),
          content: Text(
            'Votre panier contient des produits de '
            '« ${reservations.selectedPharmacyName ?? 'une autre officine'} ». '
            'Une réservation ne porte que sur une officine : le panier sera '
            'vidé pour réserver chez « ${pharmacy.name} ».',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Garder mon panier'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vider et réserver ici'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
      reservations.clearCart();
    }

    // C254 : produit déjà dans le panier : le panier s'ouvre sans rien
    // ajouter. Chaque retour sur la fiche ajoutait une boîte ; la quantité
    // ne se change que dans le panier.
    if (reservations.isInCart(product.id)) {
      context.push('/cart');
      return;
    }

    reservations.setPharmacyInfo(
      id: pharmacy.id,
      name: pharmacy.name,
      address: pharmacy.address,
      phone: pharmacy.phone,
    );
    reservations.addToCart(
      ReservationItem(
        productId: product.id,
        productName: product.name,
        genericName: product.genericName,
        dosage: product.dosage,
        pricePerUnit: stock.price,
        quantity: 1,
        prescriptionRequired: product.isPrescriptionRequired,
      ),
    );
    if (!mounted) return;
    context.push('/cart');
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
                                // C245 : puces sur plusieurs lignes à 360 px.
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildInfoChip(
                                      availability.product.manufacturer,
                                      Icons.business,
                                      context.palette.textSecondary,
                                    ),
                                    _buildInfoChip(
                                      availability.product.isGeneric
                                          ? 'Générique'
                                          : 'Princeps',
                                      Icons.local_pharmacy,
                                      availability.product.isGeneric
                                          ? context.palette.secondary
                                          : context.palette.primary,
                                    ),
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
                                    ? () => _reserve(availability, stock)
                                    : null,
                              ),
                            );
                          }),
                          if (availability.hasAvailableStock) ...[
                            const SizedBox(height: 16),
                            // C245 : la réservation se fait dans une officine
                            // précise ; chaque officine disponible se touche.
                            Text(
                              'Touchez une officine disponible pour réserver '
                              'ce produit chez elle.',
                              style: context.text.body2,
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
