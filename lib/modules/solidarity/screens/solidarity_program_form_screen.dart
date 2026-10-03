import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../models/solidarity_program.dart';
import '../providers/solidarity_provider.dart';

class SolidarityProgramFormScreen extends StatefulWidget {
  const SolidarityProgramFormScreen({super.key});

  @override
  State<SolidarityProgramFormScreen> createState() =>
      _SolidarityProgramFormScreenState();
}

class _SolidarityProgramFormScreenState
    extends State<SolidarityProgramFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  String _type = 'free_medication';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  static const _typeOptions = {
    'free_medication': 'Médicaments gratuits',
    'subsidized_care': 'Soins subventionnés',
    'emergency_aid': 'Aide d\'urgence',
    'health_education': 'Éducation sanitaire',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _endDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final now = DateTime.now();
    final program = SolidarityProgram(
      id: 'temp_${now.millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _type,
      startDate: _startDate,
      endDate: _endDate,
      budget: _budgetController.text.trim().isEmpty
          ? null
          : int.parse(_budgetController.text.trim()),
      createdAt: now,
      updatedAt: now,
    );

    final provider = context.read<SolidarityProvider>();
    final success = await provider.saveProgram(program);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Programme créé'),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erreur lors de la création'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
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
                        'Nouveau programme solidaire',
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
                              label: 'Nom du programme',
                              hint: 'Ex: Insuline gratuite Ramadan 2026',
                              controller: _nameController,
                              prefixIcon: Icons.handshake,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un nom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Description (optionnel)',
                              hint: 'Détails du programme',
                              controller: _descriptionController,
                              prefixIcon: Icons.description,
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _type,
                              decoration: const InputDecoration(
                                labelText: 'Type de programme',
                                border: OutlineInputBorder(),
                              ),
                              items: _typeOptions.entries
                                  .map(
                                    (entry) => DropdownMenuItem(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _type = value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            // C226 : les ListTile peignent leur fond et leurs
                            // effets sur le Material le plus proche ; la carte
                            // colorée qui les entoure les masquait (assertion
                            // Flutter en debug, relevée par C232).
                            Material(
                              type: MaterialType.transparency,
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Date de début'),
                                    subtitle: Text(_formatDate(_startDate)),
                                    leading: const Icon(Icons.calendar_today),
                                    onTap: _pickStartDate,
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text(
                                      'Date de fin (optionnel)',
                                    ),
                                    subtitle: Text(
                                      _endDate != null
                                          ? _formatDate(_endDate!)
                                          : 'Non définie',
                                    ),
                                    leading: const Icon(Icons.event_busy),
                                    onTap: _pickEndDate,
                                    trailing: _endDate != null
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () =>
                                                setState(() => _endDate = null),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Budget (GNF, optionnel)',
                              hint: 'Ex: 5 000 000',
                              controller: _budgetController,
                              prefixIcon: Icons.savings,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }
                                if (int.tryParse(value.trim()) == null) {
                                  return 'Budget invalide';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: _isLoading
                            ? 'Création...'
                            : 'Créer le programme',
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
}
