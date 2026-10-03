import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../providers/support_provider.dart';
import '../models/ticket.dart';
import '../models/support_category.dart';

// Codes de categorie correspondant a un litige potentiel (commande, paiement
// ou livraison) -- voir seed 20260827008000_support.sql. Pas de categorie
// "commande" dediee dans le referentiel actuel : une facture ou une
// livraison peuvent toutes deux porter un litige de commande, d'ou le
// selecteur dispute_category propose dans le bloc conditionnel plutot qu'un
// mapping 1:1 avec la categorie choisie.
const _disputeEligibleCategoryCodes = {'BILL', 'DELIV'};

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _disputedAmountController = TextEditingController();
  final _disputeReferenceController = TextEditingController();
  String? _categoryId;
  String _priority = 'medium';
  String _disputeCategory = 'order';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _disputedAmountController.dispose();
    _disputeReferenceController.dispose();
    super.dispose();
  }

  bool _isDisputeEligible(List<SupportCategory> categories) {
    final selected = categories.where((c) => c.id == _categoryId);
    if (selected.isEmpty) return false;
    return _disputeEligibleCategoryCodes.contains(selected.first.code);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<SupportProvider>().categories;
    final showDisputeFields = _isDisputeEligible(categories);
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
                        'Nouveau ticket de support',
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
                            // Category
                            DropdownButtonFormField<String>(
                              value: _categoryId,
                              decoration: const InputDecoration(
                                labelText: 'Catégorie',
                                border: OutlineInputBorder(),
                              ),
                              items: categories.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat.id,
                                  child: Text(cat.name),
                                );
                              }).toList(),
                              onChanged: categories.isEmpty
                                  ? null
                                  : (value) =>
                                        setState(() => _categoryId = value),
                              validator: (value) => value == null
                                  ? 'Veuillez sélectionner une catégorie'
                                  : null,
                            ),
                            if (categories.isEmpty) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Chargement des catégories...',
                                style: PharmaConnectTypography.micro,
                              ),
                            ],
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Sujet',
                              hint: 'Résumez votre demande',
                              controller: _subjectController,
                              prefixIcon: Icons.title,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un sujet';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Description',
                              hint: 'Décrivez votre problème en détail',
                              controller: _descriptionController,
                              prefixIcon: Icons.description,
                              keyboardType: TextInputType.multiline,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez décrire votre problème';
                                }
                                if (value.trim().length < 10) {
                                  return 'Veuillez fournir plus de détails (minimum 10 caractères)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            const Text(
                              'Priorité',
                              style: PharmaConnectTypography.label,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildPriorityChip(
                                  'low',
                                  'Basse',
                                  PharmaConnectColors.textSecondary,
                                ),
                                _buildPriorityChip(
                                  'medium',
                                  'Moyenne',
                                  PharmaConnectColors.accentCyan,
                                ),
                                _buildPriorityChip(
                                  'high',
                                  'Élevée',
                                  PharmaConnectColors.accentOrange,
                                ),
                                _buildPriorityChip(
                                  'critical',
                                  'Critique',
                                  PharmaConnectColors.accentRed,
                                ),
                              ],
                            ),
                            if (showDisputeFields) ...[
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),
                              const Text(
                                '⚠️ Litige lié à une commande, un paiement ou une livraison',
                                style: PharmaConnectTypography.label,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildDisputeCategoryChip(
                                    'order',
                                    'Commande',
                                  ),
                                  _buildDisputeCategoryChip(
                                    'payment',
                                    'Paiement',
                                  ),
                                  _buildDisputeCategoryChip(
                                    'delivery',
                                    'Livraison',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GlassInput(
                                label: 'Montant contesté (optionnel)',
                                hint: 'Ex. 25000',
                                controller: _disputedAmountController,
                                prefixIcon: Icons.money_off,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return null;
                                  }
                                  final parsed = num.tryParse(value.trim());
                                  if (parsed == null) {
                                    return 'Montant invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              GlassInput(
                                label: 'Référence liée (optionnel)',
                                hint:
                                    'N° de commande, de paiement ou de livraison',
                                controller: _disputeReferenceController,
                                prefixIcon: Icons.link,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: _isLoading ? 'Envoi...' : 'Envoyer',
                        isLoading: _isLoading,
                        onPressed: _submitTicket,
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

  Widget _buildPriorityChip(String value, String label, Color color) {
    final isSelected = _priority == value;
    return GestureDetector(
      onTap: () => setState(() => _priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : PharmaConnectColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildDisputeCategoryChip(String value, String label) {
    final isSelected = _disputeCategory == value;
    const color = PharmaConnectColors.accentOrange;
    return GestureDetector(
      onTap: () => setState(() => _disputeCategory = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : PharmaConnectColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = SupabaseService().currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    setState(() => _isLoading = true);

    final categories = context.read<SupportProvider>().categories;
    final isDispute = _isDisputeEligible(categories);

    final ticket = SupportTicket(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      ticketNumber: '', // Will be generated by DB
      patientId: userId,
      categoryId: _categoryId,
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      status: 'new',
      priority: _priority,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      isDispute: isDispute,
      disputeCategory: isDispute ? _disputeCategory : null,
      disputedAmount:
          isDispute && _disputedAmountController.text.trim().isNotEmpty
          ? num.tryParse(_disputedAmountController.text.trim())
          : null,
      disputeReferenceId:
          isDispute && _disputeReferenceController.text.trim().isNotEmpty
          ? _disputeReferenceController.text.trim()
          : null,
    );

    final success = await context.read<SupportProvider>().createTicket(ticket);
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket créé avec succès'),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<SupportProvider>().error ?? 'Erreur'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}
