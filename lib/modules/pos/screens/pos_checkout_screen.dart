import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/pos_provider.dart';
import '../models/pos_sale_item.dart';

class POSCheckoutScreen extends StatefulWidget {
  const POSCheckoutScreen({super.key});

  @override
  State<POSCheckoutScreen> createState() => _POSCheckoutScreenState();
}

class _POSCheckoutScreenState extends State<POSCheckoutScreen> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();

  List<Map<String, dynamic>> _mockProducts = const [
    {'id': 'p1', 'name': 'Doliprane 1000mg', 'price': 5000},
    {'id': 'p2', 'name': 'Amoxicilline 500mg', 'price': 7500},
    {'id': 'p3', 'name': 'Efferalgan 500mg', 'price': 4500},
    {'id': 'p4', 'name': 'Ibuprofène 400mg', 'price': 6000},
    {'id': 'p5', 'name': 'Ventoline 100µg', 'price': 12000},
    {'id': 'p6', 'name': 'Paracétamol 500mg', 'price': 3500},
    {'id': 'p7', 'name': 'Spasfon 80mg', 'price': 8000},
  ];

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
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
                    '🧾 Vente au comptoir',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: provider.cart.isNotEmpty
                        ? PharmaConnectColors.accentGreen.withValues(
                            alpha: 0.15,
                          )
                        : PharmaConnectColors.textSecondary.withValues(
                            alpha: 0.1,
                          ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${provider.cart.length} article${provider.cart.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: provider.cart.isNotEmpty
                          ? PharmaConnectColors.accentGreen
                          : PharmaConnectColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Product search & cart
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Search bar
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Rechercher un produit...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PrimaryButton(
                              label: 'Ajouter',
                              onPressed: () => _addProductToCart(provider),
                              width: 100,
                              height: 50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Quantity and discount
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Qté',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Slider(
                                value: provider.discountPercent,
                                min: 0,
                                max: 100,
                                onChanged: (value) {
                                  provider.setDiscount(value);
                                },
                                activeColor: PharmaConnectColors.accentPurple,
                              ),
                            ),
                            Text(
                              '${provider.discountPercent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: provider.discountPercent > 0
                                    ? PharmaConnectColors.accentPurple
                                    : PharmaConnectColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Cart items
                        Expanded(
                          child: provider.cart.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 48,
                                        color: Colors.white24,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Panier vide',
                                        style: PharmaConnectTypography.body2,
                                      ),
                                      Text(
                                        'Ajoutez des produits pour commencer',
                                        style: PharmaConnectTypography.micro,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: provider.cart.length,
                                  itemBuilder: (context, index) {
                                    final item = provider.cart[index];
                                    return _buildCartItem(item, provider);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right: Summary & checkout
                  Expanded(
                    flex: 1,
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 Résumé',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow('Total', provider.total),
                          if (provider.discountPercent > 0)
                            _buildSummaryRow(
                              'Remise (${provider.discountPercent.toStringAsFixed(0)}%)',
                              -provider.discountAmount,
                              color: PharmaConnectColors.accentPurple,
                            ),
                          _buildSummaryRow('TVA (5%)', provider.taxAmount),
                          const Divider(color: Colors.white12),
                          _buildSummaryRow(
                            'À payer',
                            provider.finalTotal,
                            isTotal: true,
                            color: PharmaConnectColors.accentCyan,
                          ),
                          const SizedBox(height: 16),

                          // Payment method
                          DropdownButtonFormField<String>(
                            value: provider.selectedPaymentMethod,
                            decoration: const InputDecoration(
                              labelText: 'Mode de paiement',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'cash',
                                child: Text('💵 Espèces'),
                              ),
                              DropdownMenuItem(
                                value: 'mobile_money',
                                child: Text('📱 Mobile Money'),
                              ),
                              DropdownMenuItem(
                                value: 'card',
                                child: Text('💳 Carte'),
                              ),
                              DropdownMenuItem(
                                value: 'insurance',
                                child: Text('🛡️ Assurance'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                provider.setPaymentMethod(value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Patient field (optional)
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Patient (optionnel)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          PrimaryButton(
                            label: provider.isCheckingOut
                                ? 'Traitement...'
                                : '💳 Finaliser la vente',
                            isLoading: provider.isCheckingOut,
                            onPressed: provider.cart.isEmpty
                                ? null
                                : () => _checkout(provider),
                          ),
                          const SizedBox(height: 8),
                          SecondaryButton(
                            label: '🔄 Vider le panier',
                            onPressed: provider.cart.isEmpty
                                ? null
                                : provider.clearCart,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(POSSaleItem item, POSProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: PharmaConnectTypography.body1.copyWith(
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
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => provider.removeFromCart(item.productId!),
            color: PharmaConnectColors.accentRed,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    Color? color,
  }) {
    final textColor =
        color ?? (isTotal ? PharmaConnectColors.accentCyan : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              color: textColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _addProductToCart(POSProvider provider) {
    final search = _searchController.text.trim();
    if (search.isEmpty) return;

    final product = _mockProducts.firstWhere(
      (p) => p['name']!.toLowerCase().contains(search.toLowerCase()),
      orElse: () => _mockProducts.first,
    );

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    final item = POSSaleItem(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      saleId: '',
      productId: product['id'],
      productName: product['name'],
      quantity: quantity,
      unitPrice: product['price'],
      totalPrice: product['price'] * quantity,
      createdAt: DateTime.now().toUtc(),
    );

    provider.addToCart(item);
    _searchController.clear();
  }

  Future<void> _checkout(POSProvider provider) async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    final success = await provider.checkout(
      pharmacyId: 'default_pharmacy', // Should come from user profile
      cashierId: userId,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vente finalisée avec succès !'),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
      context.push('/pos/receipt/${provider.currentSale?.id}');
    } else if (context.mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}
