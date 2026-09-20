import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import '../providers/marketplace_provider.dart';
import '../models/b2b_offer.dart';

class OfferCreateScreen extends StatefulWidget {
  // Audit Module 13 (B2B, 29/08/2026) : le bouton « Modifier » de
  // offer_detail_screen.dart était un no-op (`onPressed: () { // Navigate
  // to edit screen }`, jamais implémenté). Plutôt que de créer un second
  // écran quasi identique, cet écran de création accepte maintenant une
  // offre existante en édition — `MarketplaceProvider.saveOffer()` route
  // déjà create/update selon que l'id est vide/temp_ ou réel, il suffisait
  // de préremplir le formulaire et de conserver l'id/le vendeur d'origine.
  final B2BOffer? existingOffer;

  const OfferCreateScreen({super.key, this.existingOffer});

  @override
  State<OfferCreateScreen> createState() => _OfferCreateScreenState();
}

class _OfferCreateScreenState extends State<OfferCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'unité');
  final _minOrderController = TextEditingController(text: '1');
  final _expiryDateController = TextEditingController();

  DateTime? _selectedExpiryDate;
  bool _isLoading = false;

  bool get _isEditing => widget.existingOffer != null;

  @override
  void initState() {
    super.initState();
    final offer = widget.existingOffer;
    if (offer != null) {
      _productNameController.text = offer.productName;
      _descriptionController.text = offer.description ?? '';
      _priceController.text = offer.price.toString();
      _quantityController.text = offer.quantity.toString();
      _unitController.text = offer.unit;
      _minOrderController.text = offer.minOrderQuantity.toString();
      _selectedExpiryDate = offer.expiryDate;
      if (offer.expiryDate != null) {
        _expiryDateController.text = _formatDate(offer.expiryDate!);
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _minOrderController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                  Expanded(
                    child: Text(
                      _isEditing
                          ? '🛒 Modifier l\'offre B2B'
                          : '🛒 Créer une offre B2B',
                      style: PharmaConnectTypography.heading2,
                    ),
                  ),
                  const KernelBadge(),
                ],
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
                              label: 'Nom du produit',
                              hint: 'Ex: Doliprane 1000mg',
                              controller: _productNameController,
                              prefixIcon: Icons.medication,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer le nom du produit';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Description (optionnel)',
                              hint: 'Description du produit',
                              controller: _descriptionController,
                              prefixIcon: Icons.description,
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: GlassInput(
                                    label: 'Prix (GNF)',
                                    hint: 'Ex: 5000',
                                    controller: _priceController,
                                    prefixIcon: Icons.money,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Entrez un prix';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Prix invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GlassInput(
                                    label: 'Quantité',
                                    hint: 'Ex: 100',
                                    controller: _quantityController,
                                    prefixIcon: Icons.inventory,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Quantité requise';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Quantité invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: GlassInput(
                                    label: 'Unité',
                                    hint: 'Ex: unité, boîte, carton',
                                    controller: _unitController,
                                    prefixIcon: Icons.abc,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GlassInput(
                                    label: 'Commande min.',
                                    hint: '1',
                                    controller: _minOrderController,
                                    prefixIcon: Icons.vertical_align_bottom,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (int.tryParse(value) == null) {
                                          return 'Nombre invalide';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Expiry date
                            ListTile(
                              title: const Text('Date d\'expiration'),
                              subtitle: Text(
                                _selectedExpiryDate != null
                                    ? _formatDate(_selectedExpiryDate!)
                                    : 'Optionnel',
                              ),
                              leading: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(
                                    const Duration(days: 30),
                                  ),
                                  firstDate: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary:
                                              PharmaConnectColors.accentCyan,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setState(() => _selectedExpiryDate = date);
                                  _expiryDateController.text = _formatDate(
                                    date,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentPurple.withValues(
                            alpha: 0.06,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PharmaConnectColors.accentPurple.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: PharmaConnectColors.accentPurple,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Les offres B2B sont visibles par toutes les pharmacies. '
                                'Les acheteurs peuvent négocier le prix.',
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
                        label: _isLoading
                            ? (_isEditing
                                  ? 'Enregistrement...'
                                  : 'Création...')
                            : (_isEditing
                                  ? 'Enregistrer les modifications'
                                  : 'Publier l\'offre'),
                        isLoading: _isLoading,
                        onPressed: _submit,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Audit Module 13 (B2B, 29/08/2026) : utilisait
  // `SupabaseService().currentUser?.id` (l'identifiant de l'UTILISATEUR)
  // comme `sellerPharmacyId` — même bug que les policies RLS et que
  // `marketplace_home_screen.dart` (voir leurs commentaires respectifs) :
  // `b2b_offers.seller_pharmacy_id` référence `pharmacies(id)`, jamais
  // `profiles(id)`. Corrigé via `AuthProvider.pharmacyId`, comme dans tous
  // les autres modules du projet.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être rattaché à une officine vérifiée'),
        ),
      );
      return;
    }

    final price = int.tryParse(_priceController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());
    final minOrder = int.tryParse(_minOrderController.text.trim());

    if (price == null || quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vérifier les montants')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final existing = widget.existingOffer;
    final offer = B2BOffer(
      id: existing?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sellerPharmacyId: existing?.sellerPharmacyId ?? pharmacyId,
      productName: _productNameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      price: price,
      quantity: quantity,
      unit: _unitController.text.trim().isNotEmpty
          ? _unitController.text.trim()
          : 'unité',
      minOrderQuantity: minOrder ?? 1,
      expiryDate: _selectedExpiryDate,
      status: existing?.status ?? 'active',
      createdAt: existing?.createdAt ?? DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context.read<MarketplaceProvider>().saveOffer(offer);
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Offre mise à jour' : 'Offre publiée avec succès',
          ),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<MarketplaceProvider>().error ?? 'Erreur'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}
