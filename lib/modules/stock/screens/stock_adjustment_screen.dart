import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/stock_adjustment.dart';
import '../providers/stock_provider.dart';
import '../../../core/theme/palette.dart';

class StockAdjustmentScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const StockAdjustmentScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  AdjustmentReason _selectedReason = AdjustmentReason.inventoryCorrection;
  bool _isPositive = true;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    'Ajustement de stock',
                    style: context.text.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text('Produit : ${widget.productName}', style: context.text.body1),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GlassCard(
                      child: Column(
                        children: [
                          // Type d'ajustement
                          Text('Type d\'opération', style: context.text.label),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('➕ Ajout'),
                                  selected: _isPositive,
                                  onSelected: (_) =>
                                      setState(() => _isPositive = true),
                                  selectedColor: context.palette.success
                                      .withValues(alpha: 0.2),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('➖ Retrait'),
                                  selected: !_isPositive,
                                  onSelected: (_) =>
                                      setState(() => _isPositive = false),
                                  selectedColor: context.palette.danger
                                      .withValues(alpha: 0.2),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Quantité
                          GlassInput(
                            label: 'Quantité',
                            hint: '0',
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.numbers,
                          ),
                          const SizedBox(height: 16),

                          // Raison
                          Text(
                            'Raison de l\'ajustement',
                            style: context.text.label,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<AdjustmentReason>(
                            value: _selectedReason,
                            dropdownColor: context.palette.background,
                            style: context.text.body1,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: context.palette.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.palette.veil(0.24),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.palette.veil(0.24),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.palette.primary,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: AdjustmentReason.values.map((reason) {
                              return DropdownMenuItem<AdjustmentReason>(
                                value: reason,
                                child: Text(reason.label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedReason = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Notes
                          GlassInput(
                            label: 'Notes (optionnel)',
                            hint: 'Informations complémentaires...',
                            controller: _notesController,
                            prefixIcon: Icons.note,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Valider l\'ajustement',
                      isLoading: provider.isLoading,
                      onPressed: () async {
                        final quantityText = _quantityController.text.trim();
                        if (quantityText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Veuillez saisir une quantité'),
                              backgroundColor: context.palette.danger,
                            ),
                          );
                          return;
                        }

                        final quantity = int.tryParse(quantityText);
                        if (quantity == null || quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Quantité invalide'),
                              backgroundColor: context.palette.danger,
                            ),
                          );
                          return;
                        }

                        final finalQuantity = _isPositive
                            ? quantity
                            : -quantity;

                        // Audit Module 4 (29/08/2026) : userId/pharmacyId
                        // étaient codés en dur ('admin'/'Admin') — user_id
                        // est une colonne uuid en base, la chaîne littérale
                        // 'admin' faisait donc échouer l'insertion à chaque
                        // ajustement (après que stock_items ait déjà été
                        // modifié, voir StockService.adjustStock). Désormais
                        // pris depuis AuthProvider, comme l'exige RG-AUT-03
                        // (traçabilité par identifiant réel du membre
                        // d'officine).
                        final pharmacyId = auth.pharmacyId;
                        final userId = auth.userId;
                        if (pharmacyId == null || userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Compte non rattaché à une officine vérifiée',
                              ),
                              backgroundColor: context.palette.danger,
                            ),
                          );
                          return;
                        }

                        final success = await provider.adjustStock(
                          pharmacyId: pharmacyId,
                          productId: widget.productId,
                          quantity: finalQuantity,
                          reason: _selectedReason,
                          userId: userId,
                          userName:
                              auth.userEmail ?? auth.userPhone ?? 'Pharmacien',
                          notes: _notesController.text.trim(),
                        );

                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.isOffline
                                    ? 'Ajustement enregistré hors-ligne — '
                                          'sera synchronisé à la reconnexion'
                                    : 'Ajustement effectué avec succès',
                              ),
                              backgroundColor: provider.isOffline
                                  ? context.palette.warningStrong
                                  : context.palette.success,
                            ),
                          );
                          context.pop();
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.error ??
                                    'Erreur lors de l\'ajustement',
                              ),
                              backgroundColor: context.palette.danger,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
