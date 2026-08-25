import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../providers/reservation_provider.dart';
import '../widgets/cart_item_tile.dart';

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
                const Expanded(
                  child: Text(
                    'Panier',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                if (provider.hasItemsInCart) ...[
                  TextButton.icon(
                    onPressed: provider.clearCart,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Vider'),
                    style: TextButton.styleFrom(
                      foregroundColor: PharmaConnectColors.accentRed,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

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
                          const Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Votre panier est vide',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ajoutez des médicaments depuis la recherche',
                            style: PharmaConnectTypography.body2,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Rechercher des médicaments',
                            onPressed: () => context.go('/search'),
                            width: 300,
                          ),
                        ],
                      ),
                    ),
            ),

            // Total et checkout
            if (provider.hasItemsInCart) ...[
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total du panier',
                          style: PharmaConnectTypography.label,
                        ),
                        Text(
                          CurrencyFormatter.format(provider.cartTotal),
                          style: PharmaConnectTypography.kpiSmall.copyWith(
                            color: PharmaConnectColors.accentCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  PrimaryButton(
                    label: 'Passer la commande',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      context.push('/reservations/checkout');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
