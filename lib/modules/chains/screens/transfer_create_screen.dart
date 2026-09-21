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
import '../providers/chain_provider.dart';
import '../services/chain_service.dart';
import '../models/stock_transfer.dart';

// Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-1 : l'import
// `../models/transfer_item.dart` (fichier inexistant) a été supprimé.
// `TransferItem` est réellement défini dans `stock_transfer.dart`,
// déjà importé ci-dessus — confirmé par listing intégral du dossier
// `models/` de ce module (6 fichiers, aucun `transfer_item.dart`).
class TransferCreateScreen extends StatefulWidget {
  final String? groupId;

  const TransferCreateScreen({super.key, this.groupId});

  @override
  State<TransferCreateScreen> createState() => _TransferCreateScreenState();
}

class _TransferCreateScreenState extends State<TransferCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _chainService = ChainService();

  String? _fromPharmacyId;
  String? _toPharmacyId;
  final List<TransferItem> _items = [];

  // Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-7 : les listes
  // codées en dur (`_mockPharmacies`/`_mockProducts`, identifiants
  // non-UUID `ph1`/`p1`...) ont été remplacées par une lecture réelle
  // de `public.pharmacies`/`public.products` (`ChainService.getActive*()`)
  // — un transfert créé avec les anciens identifiants mockés aurait
  // échoué à l'insertion en base réelle (contrainte de clé étrangère
  // `not null references pharmacies(id)`/`references products(id)`).
  List<Map<String, dynamic>> _pharmacies = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingOptions = true;
  String? _loadError;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final pharmacies = await _chainService.getActivePharmacies();
      final products = await _chainService.getActiveProducts();
      if (!mounted) return;
      setState(() {
        _pharmacies = pharmacies;
        _products = products;
        _isLoadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoadingOptions = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
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
                  const Expanded(
                    child: Text(
                      '🚚 Transfert de stock',
                      style: PharmaConnectTypography.heading2,
                    ),
                  ),
                  const KernelBadge(),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoadingOptions)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: PharmaConnectColors.accentRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: PharmaConnectTypography.body2.copyWith(
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Réessayer',
                          onPressed: () {
                            setState(() => _isLoadingOptions = true);
                            _loadOptions();
                          },
                          width: 200,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // From pharmacy
                              DropdownButtonFormField<String>(
                                value: _fromPharmacyId,
                                decoration: const InputDecoration(
                                  labelText: 'Pharmacie source',
                                  border: OutlineInputBorder(),
                                ),
                                items: _pharmacies.map((ph) {
                                  return DropdownMenuItem<String>(
                                    value: ph['id'] as String,
                                    child: Text(ph['name'] as String),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => _fromPharmacyId = value),
                                validator: (value) => value == null
                                    ? 'Sélectionnez une pharmacie source'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // To pharmacy
                              DropdownButtonFormField<String>(
                                value: _toPharmacyId,
                                decoration: const InputDecoration(
                                  labelText: 'Pharmacie destination',
                                  border: OutlineInputBorder(),
                                ),
                                items: _pharmacies
                                    .where((ph) => ph['id'] != _fromPharmacyId)
                                    .map((ph) {
                                      return DropdownMenuItem<String>(
                                        value: ph['id'] as String,
                                        child: Text(ph['name'] as String),
                                      );
                                    })
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _toPharmacyId = value),
                                validator: (value) => value == null
                                    ? 'Sélectionnez une pharmacie destination'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // Notes
                              GlassInput(
                                label: 'Notes (optionnel)',
                                hint: 'Informations sur le transfert',
                                controller: _notesController,
                                prefixIcon: Icons.note_add,
                                keyboardType: TextInputType.multiline,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Items section
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '📦 Articles',
                                    style: PharmaConnectTypography.heading3,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: PharmaConnectColors.accentCyan,
                                    ),
                                    onPressed: _products.isEmpty
                                        ? null
                                        : _showAddItemDialog,
                                  ),
                                ],
                              ),
                              // Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-7 :
                              // rappel visible de RG-CHN-01 (seule règle du module) —
                              // le lot et la date de péremption sont désormais
                              // obligatoires à la saisie (voir `_showAddItemDialog`)
                              // et revérifiés côté serveur (trigger SQL) à la
                              // réception du transfert.
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 4),
                                child: Text(
                                  'Lot et date de péremption obligatoires (RG-CHN-01) — un lot expiré sera rejeté à la réception.',
                                  style: PharmaConnectTypography.micro.copyWith(
                                    color: PharmaConnectColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (_items.isEmpty) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Aucun article ajouté',
                                  style: PharmaConnectTypography.body2,
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                ..._items.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.04,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: PharmaConnectTypography
                                                    .body2
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              Text(
                                                'Qté: ${item.quantity} • Lot ${item.batchNumber} • Péremption ${_formatDate(item.expiryDate!)}',
                                                style: PharmaConnectTypography
                                                    .micro,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ),
                                          onPressed: () => setState(
                                            () => _items.removeAt(index),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: _isLoading
                                    ? 'Création...'
                                    : 'Créer le transfert',
                                isLoading: _isLoading,
                                onPressed: _createTransfer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TertiaryButton(
                                label: 'Annuler',
                                onPressed: () => context.pop(),
                              ),
                            ),
                          ],
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showAddItemDialog() {
    String? selectedProductId;
    final quantityController = TextEditingController();
    // Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-7 : le formulaire
    // d'ajout d'article ne collectait auparavant que le produit et la
    // quantité — RG-CHN-01 (« ne peut porter que sur des lots non
    // expirés ») ne pouvait donc structurellement jamais être vérifiée,
    // la donnée nécessaire n'étant jamais saisie. Ajout des champs lot et
    // date de péremption, tous deux désormais obligatoires.
    final batchController = TextEditingController();
    DateTime? selectedExpiryDate;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: PharmaConnectColors.primaryDeep,
          title: const Text('Ajouter un article'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Produit',
                  border: OutlineInputBorder(),
                ),
                items: _products.map((p) {
                  return DropdownMenuItem<String>(
                    value: p['id'] as String,
                    child: Text(p['name'] as String),
                  );
                }).toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedProductId = value),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantité',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: batchController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de lot',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(
                      const Duration(days: 365 * 5),
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedExpiryDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de péremption',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    selectedExpiryDate != null
                        ? _formatDate(selectedExpiryDate!)
                        : 'Sélectionner une date',
                  ),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(
                  dialogError!,
                  style: const TextStyle(
                    color: PharmaConnectColors.accentRed,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final product = _products.firstWhere(
                  (p) => p['id'] == selectedProductId,
                  orElse: () => <String, dynamic>{},
                );
                final quantity = int.tryParse(quantityController.text);
                final batchNumber = batchController.text.trim();

                if (selectedProductId == null || product.isEmpty) {
                  setDialogState(() => dialogError = 'Sélectionnez un produit');
                  return;
                }
                if (quantity == null || quantity <= 0) {
                  setDialogState(
                    () => dialogError = 'Quantité invalide',
                  );
                  return;
                }
                if (batchNumber.isEmpty) {
                  setDialogState(
                    () => dialogError = 'Le numéro de lot est obligatoire (RG-CHN-01)',
                  );
                  return;
                }
                if (selectedExpiryDate == null) {
                  setDialogState(
                    () => dialogError =
                        'La date de péremption est obligatoire (RG-CHN-01)',
                  );
                  return;
                }
                final today = DateTime.now();
                final todayDateOnly = DateTime(today.year, today.month, today.day);
                if (selectedExpiryDate!.isBefore(todayDateOnly)) {
                  setDialogState(
                    () => dialogError =
                        'Ce lot est expiré — un transfert ne peut porter que sur des lots non expirés (RG-CHN-01)',
                  );
                  return;
                }

                setState(() {
                  _items.add(
                    TransferItem(
                      id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${_items.length}',
                      transferId: '',
                      productId: selectedProductId,
                      productName: product['name'] as String,
                      quantity: quantity,
                      batchNumber: batchNumber,
                      expiryDate: selectedExpiryDate,
                      createdAt: DateTime.now().toUtc(),
                      updatedAt: DateTime.now().toUtc(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmaConnectColors.accentCyan,
                foregroundColor: PharmaConnectColors.textOnAccent,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un article')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final transfer = StockTransfer(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      fromPharmacyId: _fromPharmacyId!,
      toPharmacyId: _toPharmacyId!,
      groupId: widget.groupId,
      status: 'pending',
      transferDate: DateTime.now().toUtc(),
      notes: _notesController.text.trim(),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      items: _items,
    );

    final success = await context.read<ChainProvider>().saveTransfer(transfer);
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfert créé avec succès'),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<ChainProvider>().error ?? 'Erreur'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}
