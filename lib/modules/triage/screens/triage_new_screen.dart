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
import '../providers/triage_provider.dart';
import '../models/triage_patient.dart';
import '../models/triage_status.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class TriageNewScreen extends StatefulWidget {
  const TriageNewScreen({super.key});

  @override
  State<TriageNewScreen> createState() => _TriageNewScreenState();
}

class _TriageNewScreenState extends State<TriageNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientIdController = TextEditingController();
  final _chiefComplaintController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();
  int _priorityLevel = 3;

  bool _isLoading = false;

  @override
  void dispose() {
    _patientIdController.dispose();
    _chiefComplaintController.dispose();
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
                        'Nouveau patient triage',
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
                              label: 'ID Patient',
                              hint: 'Entrez l\'ID du patient',
                              controller: _patientIdController,
                              prefixIcon: Icons.person,
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Motif principal',
                              hint: 'Raison de la consultation',
                              controller: _chiefComplaintController,
                              prefixIcon: Icons.description,
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Symptômes',
                              hint: 'Symptômes associés',
                              controller: _symptomsController,
                              prefixIcon: Icons.medical_information,
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Notes (optionnel)',
                              hint: 'Informations complémentaires',
                              controller: _notesController,
                              prefixIcon: Icons.note_add,
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 12),
                            Text('Priorité', style: context.text.label),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (index) {
                                final level = index + 1;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _priorityLevel = level,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _priorityLevel == level
                                              ? _priorityColor(
                                                  level,
                                                ).withValues(alpha: 0.2)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: _priorityLevel == level
                                                ? _priorityColor(level)
                                                : context.palette.veil(0.24),
                                          ),
                                        ),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Text(
                                                '$level',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      _priorityLevel == level
                                                      ? FontWeight.w700
                                                      : FontWeight.w400,
                                                  color: _priorityColor(level),
                                                ),
                                              ),
                                              Text(
                                                _priorityLabel(level),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: _priorityColor(level),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: _isLoading ? 'Enregistrement...' : 'Enregistrer',
                        isLoading: _isLoading,
                        onPressed: _submitPatient,
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

  Future<void> _submitPatient() async {
    if (!_formKey.currentState!.validate()) return;

    if (_patientIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer l\'ID du patient')),
      );
      return;
    }

    final nurseId = SupabaseService().currentUser?.id;
    if (nurseId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    setState(() => _isLoading = true);

    final patient = TriagePatient(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      patientId: _patientIdController.text.trim(),
      triageNurseId: nurseId,
      arrivalTime: DateTime.now().toUtc(),
      status: TriageStatus.waiting,
      priorityLevel: _priorityLevel,
      chiefComplaint: _chiefComplaintController.text.trim(),
      symptoms: _symptomsController.text.trim(),
      notes: _notesController.text.trim(),
      vitalSigns: {},
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context.read<TriageProvider>().createPatient(patient);
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Patient enregistré en triage'),
          backgroundColor: context.palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<TriageProvider>().error ?? 'Erreur'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }

  Color _priorityColor(int level) {
    switch (level) {
      case 1:
        return context.palette.danger;
      case 2:
        return context.palette.warning;
      case 3:
        return context.palette.warningStrong;
      case 4:
        return context.palette.primary;
      case 5:
        return context.palette.success;
      default:
        return context.palette.textSecondary;
    }
  }

  String _priorityLabel(int level) {
    switch (level) {
      case 1:
        return 'Immédiat';
      case 2:
        return 'Urgent';
      case 3:
        return 'Peu urgent';
      case 4:
        return 'Non urgent';
      case 5:
        return 'Routine';
      default:
        return '';
    }
  }
}
