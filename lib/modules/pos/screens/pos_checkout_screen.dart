import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
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
import '../models/stock_product.dart';
import '../services/pos_service.dart';
import '../../auth/providers/auth_provider.dart';

class POSCheckoutScreen extends StatefulWidget {
  const POSCheckoutScreen({super.key});

  @override
  State<POSCheckoutScreen> createState() => _POSCheckoutScreenState();
}

class _POSCheckoutScreenState extends State<POSCheckoutScreen> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  final POSService _posService = POSService();

  // C201 : produits du stock réel de l'officine (plus de catalogue fictif).
  List<StockProduct> _results = [];
  bool _isSearching = false;
  String? _searchError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  /// Recherche dans le stock de l'officine (nom ou DCI) ; sans texte, les
  /// premiers produits disponibles.
  Future<void> _search() async {
    if (!mounted) return;
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final results = await _posService.searchStockProducts(
        pharmacyId,
        query: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e is POSSaleException
            ? e.message
            : 'Recherche impossible, vérifiez la connexion.';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyId = context.watch<AuthProvider>().pharmacyId;
    if (pharmacyId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Aucune officine rattachée à ce compte pharmacien.',
            style: PharmaConnectTypography.body2,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
                      '🧾 Vente au comptoir',
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
                                onChanged: _onSearchChanged,
                                onSubmitted: (_) => _search(),
                                textInputAction: TextInputAction.search,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Rechercher un produit en stock (nom ou DCI)...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PrimaryButton(
                              label: 'Rechercher',
                              onPressed: _search,
                              width: 120,
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
                        const SizedBox(height: 8),
                        _buildSearchResults(provider),
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
                if (item.prescriptionRequired)
                  InkWell(
                    onTap: () => provider.setPrescriptionChecked(
                      item.productId!,
                      !item.prescriptionChecked,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.prescriptionChecked
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 18,
                            color: item.prescriptionChecked
                                ? PharmaConnectColors.accentGreen
                                : PharmaConnectColors.accentOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.prescriptionChecked
                                ? 'Ordonnance vue'
                                : 'Sur ordonnance : confirmer l\'ordonnance',
                            style: PharmaConnectTypography.micro.copyWith(
                              color: item.prescriptionChecked
                                  ? PharmaConnectColors.accentGreen
                                  : PharmaConnectColors.accentOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildSearchResults(POSProvider provider) {
    if (_isSearching && _results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_searchError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _searchError!,
          style: PharmaConnectTypography.body2.copyWith(
            color: PharmaConnectColors.accentRed,
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _searchController.text.trim().isEmpty
              ? 'Aucun produit dans le stock de l\'officine'
              : 'Aucun produit en stock ne correspond à la recherche',
          style: PharmaConnectTypography.body2,
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _results.length,
        itemBuilder: (context, index) =>
            _buildResultTile(_results[index], provider),
      ),
    );
  }

  Widget _buildResultTile(StockProduct product, POSProvider provider) {
    final remaining =
        product.availableQuantity - provider.quantityInCart(product.productId);
    final canAdd = remaining > 0 && product.unitPrice > 0;
    final details = [
      if (product.form != null && product.form!.isNotEmpty) product.form!,
      if (product.genericName != null &&
          product.genericName!.isNotEmpty &&
          product.genericName != product.name)
        product.genericName!,
    ].join(' · ');

    return InkWell(
      onTap: canAdd ? () => _addStockProduct(product, provider) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: canAdd ? 0.05 : 0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.displayName,
                          style: PharmaConnectTypography.body1.copyWith(
                            fontWeight: FontWeight.w500,
                            color: canAdd
                                ? null
                                : PharmaConnectColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.prescriptionRequired) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: PharmaConnectColors.accentOrange.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Ordonnance',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: PharmaConnectColors.accentOrange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    [
                      if (details.isNotEmpty) details,
                      product.isAvailable
                          ? '${product.availableQuantity} disponible${product.availableQuantity > 1 ? 's' : ''}'
                          : 'Rupture (aucun lot vendable)',
                    ].join(' · '),
                    style: PharmaConnectTypography.micro,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              product.unitPrice > 0
                  ? CurrencyFormatter.format(product.unitPrice)
                  : 'Prix non renseigné',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: canAdd
                    ? PharmaConnectColors.accentCyan
                    : PharmaConnectColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.add_circle_outline,
              size: 20,
              color: canAdd ? PharmaConnectColors.accentGreen : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  /// Ajoute un produit du stock au panier. Le lot n'est pas choisi ici : le
  /// serveur prend les lots dont la péremption est la plus proche (D60).
  void _addStockProduct(StockProduct product, POSProvider provider) {
    final requested = int.tryParse(_quantityController.text.trim()) ?? 1;
    if (requested <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quantité invalide')));
      return;
    }
    final remaining =
        product.availableQuantity - provider.quantityInCart(product.productId);
    if (requested > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remaining > 0
                ? 'Stock insuffisant : $remaining ${product.displayName} encore disponible${remaining > 1 ? 's' : ''}'
                : 'Tout le stock disponible de ${product.displayName} est déjà dans le panier',
          ),
          backgroundColor: PharmaConnectColors.accentOrange,
        ),
      );
      return;
    }

    provider.addToCart(
      POSSaleItem(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        saleId: '',
        productId: product.productId,
        productName: product.displayName,
        quantity: requested,
        unitPrice: product.unitPrice,
        totalPrice: product.unitPrice * requested,
        prescriptionRequired: product.prescriptionRequired,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    _quantityController.text = '1';
  }

  /// D60 : avertissement non bloquant pour les produits sur ordonnance dont
  /// l'ordonnance n'a pas été confirmée. Renvoie false si la vente est annulée.
  Future<bool> _confirmPrescriptions(POSProvider provider) async {
    final unchecked = provider.uncheckedPrescriptionItems;
    if (unchecked.isEmpty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Médicaments sur ordonnance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ces produits sont délivrés sur ordonnance :',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 8),
            for (final item in unchecked)
              Text(
                '• ${item.productName}',
                style: PharmaConnectTypography.body1,
              ),
            const SizedBox(height: 12),
            const Text(
              'Votre réponse est enregistrée avec la vente.',
              style: PharmaConnectTypography.micro,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'without'),
            child: const Text('Vendre sans ordonnance'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'checked'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentGreen,
              foregroundColor: PharmaConnectColors.textPrimary,
            ),
            child: const Text('Ordonnance vue'),
          ),
        ],
      ),
    );
    if (choice == null) return false;
    if (choice == 'checked') provider.checkAllPrescriptions();
    return true;
  }

  Future<void> _checkout(POSProvider provider) async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune officine rattachée à ce compte')),
      );
      return;
    }

    if (!await _confirmPrescriptions(provider)) return;
    if (!mounted) return;

    final success = await provider.checkout(
      pharmacyId: pharmacyId,
      cashierId: userId,
    );
    if (success) unawaited(_search());

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
