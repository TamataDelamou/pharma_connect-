import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:pharma_connect/modules/catalog/providers/catalog_provider.dart';
import 'package:pharma_connect/shared/models/product.dart';
import '../providers/returns_provider.dart';
import '../models/customer_return.dart';
import '../models/customer_return_item.dart';
import '../../auth/providers/auth_provider.dart';

class CustomerReturnCreateScreen extends StatefulWidget {
  const CustomerReturnCreateScreen({super.key});

  @override
  State<CustomerReturnCreateScreen> createState() =>
      _CustomerReturnCreateScreenState();
}

class _CustomerReturnCreateScreenState
    extends State<CustomerReturnCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  // Sélection par identifiant brut : aucun composant de sélection
  // client/vente réutilisable n'existe dans le codebase, même motif déjà
  // documenté pour EnrollmentFormScreen (ASR-3).
  final _customerIdController = TextEditingController();
  final _saleIdController = TextEditingController();
  final _reasonTextController = TextEditingController();
  final _notesController = TextEditingController();
  final _productSearchController = TextEditingController();

  String? _selectedReasonId;
  bool _isLoading = false;
  final List<CustomerReturnItem> _items = [];

  int get _computedTotal =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReturnsProvider>().loadReasons(category: 'customer');
    });
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _saleIdController.dispose();
    _reasonTextController.dispose();
    _notesController.dispose();
    _productSearchController.dispose();
    super.dispose();
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

    final reasons = context.watch<ReturnsProvider>().reasons;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                        '🔄 Nouveau retour client',
                        style: PharmaConnectTypography.heading2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: [const KernelBadge()],
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
                            GlassInput(
                              label: 'Identifiant client (optionnel)',
                              hint: 'UUID du client',
                              controller: _customerIdController,
                              prefixIcon: Icons.person,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Identifiant vente (optionnel)',
                              hint: 'UUID de la vente concernée',
                              controller: _saleIdController,
                              prefixIcon: Icons.receipt,
                            ),
                            const SizedBox(height: 12),

                            DropdownButtonFormField<String>(
                              value: _selectedReasonId,
                              decoration: const InputDecoration(
                                labelText: 'Motif du retour',
                                border: OutlineInputBorder(),
                              ),
                              items: reasons.map((reason) {
                                return DropdownMenuItem<String>(
                                  value: reason.id,
                                  child: Text(reason.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedReasonId = value);
                              },
                              validator: (value) {
                                if (value == null &&
                                    _reasonTextController.text.trim().isEmpty) {
                                  return 'Sélectionnez un motif ou décrivez-le';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Précision sur le motif (optionnel)',
                              controller: _reasonTextController,
                              prefixIcon: Icons.description,
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Notes (optionnel)',
                              controller: _notesController,
                              prefixIcon: Icons.notes,
                              keyboardType: TextInputType.multiline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Articles retournés',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      GlassInput(
                        label: '',
                        hint: 'Rechercher un médicament, DCI, fabricant...',
                        controller: _productSearchController,
                        prefixIcon: Icons.search,
                        onChanged: (value) {
                          context.read<CatalogProvider>().searchProducts(value);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildProductResults(),
                      const SizedBox(height: 12),

                      if (_items.isNotEmpty) ...[
                        ..._items.map(_buildItemTile),
                        const Divider(color: Colors.white12),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Text(
                                'Montant total',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Text(
                                CurrencyFormatter.format(_computedTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Aucun article ajouté pour l\'instant',
                            style: PharmaConnectTypography.body2.copyWith(
                              color: PharmaConnectColors.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentCyan.withValues(
                            alpha: 0.06,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PharmaConnectColors.accentCyan.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: PharmaConnectColors.accentCyan,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Le retour est créé en attente ; il devra être approuvé pour déclencher le remboursement.',
                                style: PharmaConnectTypography.micro.copyWith(
                                  color: PharmaConnectColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: _isLoading ? 'Création...' : 'Créer le retour',
                        isLoading: _isLoading,
                        onPressed: _createReturn,
                      ),
                      const SizedBox(height: 8),
                      TertiaryButton(
                        label: 'Annuler',
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductResults() {
    final provider = context.watch<CatalogProvider>();
    if (_productSearchController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Aucun produit trouvé',
          style: PharmaConnectTypography.body2,
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: provider.products.length,
        itemBuilder: (context, index) {
          final product = provider.products[index];
          return ListTile(
            dense: true,
            title: Text(product.name, style: PharmaConnectTypography.body2),
            subtitle: Text(
              '${product.genericName} • ${product.dosage} • ${product.form}',
              style: PharmaConnectTypography.micro,
            ),
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () => _addProduct(product),
          );
        },
      ),
    );
  }

  void _addProduct(Product product) {
    setState(() {
      _items.add(
        CustomerReturnItem(
          id: _uuid.v4(),
          returnId: '',
          productId: product.id,
          productName: product.name,
          quantity: 1,
          unitPrice: 0,
          totalPrice: 0,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      _productSearchController.clear();
      context.read<CatalogProvider>().searchProducts('');
    });
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  void _updateItem(
    String id, {
    int? quantity,
    int? unitPrice,
    String? condition,
  }) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1) return;
      final current = _items[index];
      final newQuantity = quantity ?? current.quantity;
      final newUnitPrice = unitPrice ?? current.unitPrice;
      _items[index] = current.copyWith(
        quantity: newQuantity,
        unitPrice: newUnitPrice,
        totalPrice: newQuantity * newUnitPrice,
        condition: condition ?? current.condition,
      );
    });
  }

  Widget _buildItemTile(CustomerReturnItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: PharmaConnectTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: PharmaConnectColors.accentRed,
                  ),
                  onPressed: () => _removeItem(item.id),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final qty = int.tryParse(value);
                      if (qty != null && qty > 0) {
                        _updateItem(item.id, quantity: qty);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire (GNF)',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final price = int.tryParse(value);
                      if (price != null && price >= 0) {
                        _updateItem(item.id, unitPrice: price);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: item.condition,
              decoration: const InputDecoration(
                labelText: 'État (optionnel)',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'new', child: Text('Neuf')),
                DropdownMenuItem(value: 'used', child: Text('Usagé')),
                DropdownMenuItem(value: 'damaged', child: Text('Endommagé')),
                DropdownMenuItem(value: 'expired', child: Text('Périmé')),
              ],
              onChanged: (value) => _updateItem(item.id, condition: value),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Sous-total : ${CurrencyFormatter.format(item.totalPrice)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createReturn() async {
    if (!_formKey.currentState!.validate()) return;

    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune officine rattachée à ce compte')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now().toUtc();
    final returnData = CustomerReturn(
      id: '',
      pharmacyId: pharmacyId,
      customerId: _customerIdController.text.trim().isNotEmpty
          ? _customerIdController.text.trim()
          : null,
      saleId: _saleIdController.text.trim().isNotEmpty
          ? _saleIdController.text.trim()
          : null,
      returnNumber: '',
      returnDate: now,
      reasonId: _selectedReasonId,
      reasonText: _reasonTextController.text.trim().isNotEmpty
          ? _reasonTextController.text.trim()
          : null,
      status: ReturnStatus.pending,
      totalAmount: _computedTotal,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: now,
      updatedAt: now,
      items: _items.isNotEmpty ? _items : null,
    );

    final success = await context.read<ReturnsProvider>().createCustomerReturn(
      returnData,
    );
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      final saved = context.read<ReturnsProvider>().selectedCustomerReturn;
      if (saved != null) {
        context.go('/returns/customer/${saved.id}');
      } else {
        context.pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retour créé avec succès'),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<ReturnsProvider>().error ??
                'Erreur lors de la création',
          ),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}
