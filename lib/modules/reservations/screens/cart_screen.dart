import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../providers/reservation_provider.dart';
import '../widgets/cart_item_tile.dart';
import '../../../core/theme/palette.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

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
                      'Panier',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (provider.hasItemsInCart) ...[
                  TextButton.icon(
                    onPressed: provider.clearCart,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Vider'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.palette.danger,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // C245 : l'officine dans laquelle le panier sera réservé.
            if (provider.hasItemsInCart &&
                provider.selectedPharmacyName != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.local_pharmacy,
                    size: 18,
                    color: context.palette.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'À retirer chez ${provider.selectedPharmacyName}',
                      style: context.text.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Contenu
            Expanded(
              child: provider.hasItemsInCart
                  ? ListView.builder(
                      itemCount: provider.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = provider.cartItems[index];
                        return CartItemTile(
                          item: item,
                          onRemove: () =>
                              provider.removeFromCart(item.productId),
                          onQuantityChanged: (qty) {
                            provider.updateCartItemQuantity(
                              item.productId,
                              qty,
                            );
                          },
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: context.palette.veil(0.24),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Votre panier est vide',
                            style: context.text.heading3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez des médicaments depuis la recherche',
                            style: context.text.body2,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Rechercher des médicaments',
                            onPressed: () => context.go('/search'),
                            // C268 : sur toute la largeur en téléphone ; à
                            // 300 px, le libellé était coupé avec une police
                            // agrandie.
                            width: isCompactWidth(context)
                                ? double.infinity
                                : 300,
                          ),
                        ],
                      ),
                    ),
            ),

            // Total et checkout
            if (provider.hasItemsInCart) ...[
              Divider(color: context.palette.veil(0.12)),
              const SizedBox(height: 16),
              // C245 : bouton sous le total, sur toute la largeur. Dans une
              // ligne, sa largeur infinie cassait l'affichage du panier rempli.
              Text('Total du panier', style: context.text.label),
              Text(
                CurrencyFormatter.format(provider.cartTotal),
                style: context.text.kpiSmall.copyWith(
                  color: context.palette.primary,
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Passer la commande',
                icon: Icons.arrow_forward,
                onPressed: () {
                  context.push('/reservations/checkout');
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
