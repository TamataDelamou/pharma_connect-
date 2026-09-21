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
import '../providers/returns_provider.dart';
import '../models/customer_return.dart';

class CustomerReturnCreateScreen extends StatefulWidget {
  const CustomerReturnCreateScreen({super.key});

  @override
  State<CustomerReturnCreateScreen> createState() =>
      _CustomerReturnCreateScreenState();
}

class _CustomerReturnCreateScreenState
    extends State<CustomerReturnCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  // Sélection par identifiant brut : aucun composant de sélection
  // client/vente réutilisable n'existe dans le codebase, même motif déjà
  // documenté pour EnrollmentFormScreen (ASR-3).
  final _customerIdController = TextEditingController();
  final _saleIdController = TextEditingController();
  final _reasonTextController = TextEditingController();
  final _notesController = TextEditingController();
  // Point non tranché, signalé en section 6 du rapport : aucun écran de
  // sélection de produits n'existe pour saisir les articles retournés
  // (quantités/prix par ligne). En attendant cet arbitrage, le montant
  // total est saisi manuellement plutôt que calculé à partir d'items.
  final _totalAmountController = TextEditingController();

  String? _selectedReasonId;
  bool _isLoading = false;

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
    _totalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reasons = context.watch<ReturnsProvider>().reasons;

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
                      '🔄 Nouveau retour client',
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
                                    _reasonTextController.text
                                        .trim()
                                        .isEmpty) {
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
                              label: 'Montant total du retour (GNF)',
                              hint: 'Ex: 50000',
                              controller: _totalAmountController,
                              prefixIcon: Icons.payments,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final amount = int.tryParse(value ?? '');
                                if (amount == null || amount <= 0) {
                                  return 'Montant invalide';
                                }
                                return null;
                              },
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

  Future<void> _createReturn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now().toUtc();
    final returnData = CustomerReturn(
      id: '',
      pharmacyId: 'default_pharmacy',
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
      totalAmount: int.parse(_totalAmountController.text.trim()),
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: now,
      updatedAt: now,
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
