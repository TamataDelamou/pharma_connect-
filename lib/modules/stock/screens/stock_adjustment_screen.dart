import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../models/stock_adjustment.dart';
import '../providers/stock_provider.dart';

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
                Expanded(
                  child: Text(
                    'Ajustement de stock',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Produit : ${widget.productName}',
              style: PharmaConnectTypography.body1,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GlassCard(
                      child: Column(
                        children: [
                          // Type d'ajustement
                          const Text(
                            'Type d\'opération',
                            style: PharmaConnectTypography.label,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('➕ Ajout'),
                                  selected: _isPositive,
                                  onSelected: (_) =>
                                      setState(() => _isPositive = true),
                                  selectedColor: PharmaConnectColors.accentGreen
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
                                  selectedColor: PharmaConnectColors.accentRed
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
                          const Text(
                            'Raison de l\'ajustement',
                            style: PharmaConnectTypography.label,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<AdjustmentReason>(
                            value: _selectedReason,
                            dropdownColor: PharmaConnectColors.primaryDeep,
                            style: PharmaConnectTypography.body1,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: PharmaConnectColors.accentCyan,
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
                            const SnackBar(
                              content: Text('Veuillez saisir une quantité'),
                              backgroundColor: PharmaConnectColors.accentRed,
                            ),
                          );
                          return;
                        }

                        final quantity = int.tryParse(quantityText);
                        if (quantity == null || quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Quantité invalide'),
                              backgroundColor: PharmaConnectColors.accentRed,
                            ),
                          );
                          return;
                        }

                        final finalQuantity = _isPositive
                            ? quantity
                            : -quantity;

                        final success = await provider.adjustStock(
                          productId: widget.productId,
                          quantity: finalQuantity,
                          reason: _selectedReason,
                          userId: 'admin', // TODO: récupérer de l'auth
                          userName: 'Admin',
                          notes: _notesController.text.trim(),
                        );

                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ajustement effectué avec succès'),
                              backgroundColor: PharmaConnectColors.accentGreen,
                            ),
                          );
                          context.pop();
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur lors de l\'ajustement'),
                              backgroundColor: PharmaConnectColors.accentRed,
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
