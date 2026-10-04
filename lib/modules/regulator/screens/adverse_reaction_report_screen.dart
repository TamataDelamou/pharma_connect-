import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../providers/regulator_provider.dart';
import '../models/adverse_reaction.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class AdverseReactionReportScreen extends StatefulWidget {
  const AdverseReactionReportScreen({super.key});

  @override
  State<AdverseReactionReportScreen> createState() =>
      _AdverseReactionReportScreenState();
}

class _AdverseReactionReportScreenState
    extends State<AdverseReactionReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _reactionDate;
  String? _severity;
  String? _outcome;
  bool _treatmentRequired = false;
  bool _hospitalizationRequired = false;
  String? _reporterType;

  bool _isLoading = false;

  @override
  void dispose() {
    _medicationController.dispose();
    _symptomsController.dispose();
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
              // C233 : en-tête adaptable (actions sous le titre sur téléphone).
              HeaderRow(
                leading: Row(
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
                        'Signaler un effet indésirable',
                        style: context.text.heading2,
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
                              label: 'Médicament',
                              hint: 'Nom du médicament suspecté',
                              controller: _medicationController,
                              prefixIcon: Icons.medication,
                            ),
                            const SizedBox(height: 12),

                            // Reaction date
                            ListTile(
                              title: const Text('Date de la réaction'),
                              subtitle: Text(
                                _reactionDate != null
                                    ? _formatDate(_reactionDate!)
                                    : 'Sélectionnez une date',
                              ),
                              leading: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 365),
                                  ),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: context.palette.primary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setState(() => _reactionDate = date);
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Symptômes',
                              hint: 'Description des symptômes',
                              controller: _symptomsController,
                              prefixIcon: Icons.medical_information,
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 12),

                            // Severity
                            DropdownButtonFormField<String>(
                              value: _severity,
                              decoration: const InputDecoration(
                                labelText: 'Gravité',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'mild',
                                  child: Text('Léger'),
                                ),
                                DropdownMenuItem(
                                  value: 'moderate',
                                  child: Text('Modéré'),
                                ),
                                DropdownMenuItem(
                                  value: 'severe',
                                  child: Text('Sévère'),
                                ),
                                DropdownMenuItem(
                                  value: 'life_threatening',
                                  child: Text('Engage le pronostic vital'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _severity = value),
                            ),
                            const SizedBox(height: 12),

                            // Outcome
                            DropdownButtonFormField<String>(
                              value: _outcome,
                              decoration: const InputDecoration(
                                labelText: 'Évolution (optionnel)',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'recovered',
                                  child: Text('Rétabli'),
                                ),
                                DropdownMenuItem(
                                  value: 'recovering',
                                  child: Text('En voie de guérison'),
                                ),
                                DropdownMenuItem(
                                  value: 'ongoing',
                                  child: Text('En cours'),
                                ),
                                DropdownMenuItem(
                                  value: 'permanent_damage',
                                  child: Text('Séquelles permanentes'),
                                ),
                                DropdownMenuItem(
                                  value: 'death',
                                  child: Text('Décès'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _outcome = value),
                            ),
                            const SizedBox(height: 12),

                            // Reporter type
                            DropdownButtonFormField<String>(
                              value: _reporterType,
                              decoration: const InputDecoration(
                                labelText: 'Vous êtes',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'patient',
                                  child: Text('Patient'),
                                ),
                                DropdownMenuItem(
                                  value: 'pharmacist',
                                  child: Text('Pharmacien'),
                                ),
                                DropdownMenuItem(
                                  value: 'doctor',
                                  child: Text('Médecin'),
                                ),
                                DropdownMenuItem(
                                  value: 'nurse',
                                  child: Text('Infirmier'),
                                ),
                                DropdownMenuItem(
                                  value: 'other',
                                  child: Text('Autre'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _reporterType = value),
                            ),
                            const SizedBox(height: 12),

                            // Checkboxes
                            CheckboxListTile(
                              value: _treatmentRequired,
                              onChanged: (v) => setState(
                                () => _treatmentRequired = v ?? false,
                              ),
                              title: const Text(
                                'Un traitement a été nécessaire',
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              value: _hospitalizationRequired,
                              onChanged: (v) => setState(
                                () => _hospitalizationRequired = v ?? false,
                              ),
                              title: const Text(
                                'Une hospitalisation a été nécessaire',
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Notes (optionnel)',
                              hint: 'Informations complémentaires',
                              controller: _notesController,
                              prefixIcon: Icons.note_add,
                              keyboardType: TextInputType.multiline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: _isLoading ? 'Envoi...' : 'Signaler',
                        isLoading: _isLoading,
                        onPressed: _submitReport,
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

  Future<void> _submitReport() async {
    final palette = context.palette;
    if (!_formKey.currentState!.validate()) return;

    if (_medicationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer le médicament')),
      );
      return;
    }

    if (_symptomsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez décrire les symptômes')),
      );
      return;
    }

    if (_severity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer la gravité')),
      );
      return;
    }

    if (_reactionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date')),
      );
      return;
    }

    if (_reporterType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer votre statut')),
      );
      return;
    }

    final userId = SupabaseService().currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    setState(() => _isLoading = true);

    final reaction = AdverseReaction(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      patientId: null, // Could be filled if patient is not the reporter
      reporterId: userId,
      reporterType: _reporterType!,
      medicationName: _medicationController.text.trim(),
      reactionDate: _reactionDate!,
      reportedAt: DateTime.now().toUtc(),
      symptoms: _symptomsController.text.trim(),
      severity: _severity!,
      outcome: _outcome,
      treatmentRequired: _treatmentRequired,
      hospitalizationRequired: _hospitalizationRequired,
      notes: _notesController.text.trim(),
      status: 'pending',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context.read<RegulatorProvider>().saveReaction(
      reaction,
    );
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signalement envoyé avec succès'),
          backgroundColor: palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<RegulatorProvider>().error ??
                'Erreur lors de l\'envoi',
          ),
          backgroundColor: palette.danger,
        ),
      );
    }
  }
}
