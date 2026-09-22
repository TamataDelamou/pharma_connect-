import 'package:flutter/material.dart';
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

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _categoryId;
  String _priority = 'medium';

  bool _isLoading = false;

  // Mock categories (will be loaded from API)
  final List<Map<String, String>> _categories = const [
    {'id': '1', 'name': 'Technique / App'},
    {'id': '2', 'name': 'Facturation'},
    {'id': '3', 'name': 'Médicaments'},
    {'id': '4', 'name': 'Livraison'},
    {'id': '5', 'name': 'Compte utilisateur'},
    {'id': '6', 'name': 'Autre'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
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
                      'Nouveau ticket de support',
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
                            // Category
                            DropdownButtonFormField<String>(
                              value: _categoryId,
                              decoration: const InputDecoration(
                                labelText: 'Catégorie',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat['id'],
                                  child: Text(cat['name']!),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _categoryId = value),
                              validator: (value) => value == null
                                  ? 'Veuillez sélectionner une catégorie'
                                  : null,
                            ),
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
