import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../models/health_record.dart';
import '../providers/health_record_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

// Simple helper to generate temp id
String _tempId() => 'temp_${DateTime.now().millisecondsSinceEpoch}';

class HealthRecordEditScreen extends StatefulWidget {
  final String? recordId;

  const HealthRecordEditScreen({super.key, this.recordId});

  @override
  State<HealthRecordEditScreen> createState() => _HealthRecordEditScreenState();
}

class _HealthRecordEditScreenState extends State<HealthRecordEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _patientId;
  String? _bloodType;
  int? _height;
  int? _weight;
  String? _notes;

  // Lists for sub-items – we keep them as simple lists of strings for demo
  // In a more advanced version, you'd have full CRUD for each sub-item
  final List<Allergy> _allergies = [];
  final List<MedicalCondition> _conditions = [];
  final List<Medication> _medications = [];
  final List<Vaccination> _vaccinations = [];

  // Controllers for adding sub-items
  final _allergyController = TextEditingController();
  final _conditionController = TextEditingController();
  final _medicationController = TextEditingController();
  final _vaccinationController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _patientId = SupabaseService().currentUser?.id ?? '';
    if (widget.recordId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<HealthRecordProvider>();
        provider.loadRecord(widget.recordId!);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.recordId != null) {
      final record = context.watch<HealthRecordProvider>().selectedRecord;
      if (record != null && mounted) {
        _bloodType = record.bloodType;
        _height = record.height;
        _weight = record.weight;
        _notes = record.notes;
        _allergies.clear();
        _allergies.addAll(record.allergies);
        _conditions.clear();
        _conditions.addAll(record.medicalConditions);
        _medications.clear();
        _medications.addAll(record.medications);
        _vaccinations.clear();
        _vaccinations.addAll(record.vaccinations);
      }
    }
  }

  @override
  void dispose() {
    _allergyController.dispose();
    _conditionController.dispose();
    _medicationController.dispose();
    _vaccinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthRecordProvider>();

    if (widget.recordId != null && provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                      widget.recordId == null
                          ? 'Nouveau dossier'
                          : 'Modifier le dossier',
                      style: context.text.heading2,
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
                            // Blood type
                            DropdownButtonFormField<String>(
                              value: _bloodType,
                              decoration: const InputDecoration(
                                labelText: 'Groupe sanguin',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  [
                                        'A+',
                                        'A-',
                                        'B+',
                                        'B-',
                                        'AB+',
                                        'AB-',
                                        'O+',
                                        'O-',
                                      ]
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(type),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) =>
                                  setState(() => _bloodType = value),
                            ),
                            const SizedBox(height: 12),

                            // Height
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Taille (cm)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: _height?.toString() ?? '',
                              onChanged: (value) =>
                                  _height = int.tryParse(value),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (int.tryParse(value) == null) {
                                    return 'Veuillez entrer un nombre valide';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Weight
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Poids (kg)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: _weight?.toString() ?? '',
                              onChanged: (value) =>
                                  _weight = int.tryParse(value),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (int.tryParse(value) == null) {
                                    return 'Veuillez entrer un nombre valide';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Notes
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              initialValue: _notes ?? '',
                              onChanged: (value) => _notes = value,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Allergies (add and list)
                      _buildSubSection(
                        title: 'Allergies',
                        list: _allergies,
                        addController: _allergyController,
                        onAdd: () {
                          final name = _allergyController.text.trim();
                          if (name.isNotEmpty) {
                            setState(() {
                              _allergies.add(
                                Allergy(id: _tempId(), name: name),
                              );
                              _allergyController.clear();
                            });
                          }
                        },
                        onRemove: (index) {
                          setState(() => _allergies.removeAt(index));
                        },
                        displayBuilder: (item) => item.name,
                      ),
                      const SizedBox(height: 16),

                      // Conditions
                      _buildSubSection(
                        title: 'Antécédents médicaux',
                        list: _conditions,
                        addController: _conditionController,
                        onAdd: () {
                          final name = _conditionController.text.trim();
                          if (name.isNotEmpty) {
                            setState(() {
                              _conditions.add(
                                MedicalCondition(id: _tempId(), name: name),
                              );
                              _conditionController.clear();
                            });
                          }
                        },
                        onRemove: (index) {
                          setState(() => _conditions.removeAt(index));
                        },
                        displayBuilder: (item) => item.name,
                      ),
                      const SizedBox(height: 16),

                      // Medications
                      _buildSubSection(
                        title: 'Traitements en cours',
                        list: _medications,
                        addController: _medicationController,
                        onAdd: () {
                          final name = _medicationController.text.trim();
                          if (name.isNotEmpty) {
                            setState(() {
                              _medications.add(
                                Medication(id: _tempId(), name: name),
                              );
                              _medicationController.clear();
                            });
                          }
                        },
                        onRemove: (index) {
                          setState(() => _medications.removeAt(index));
                        },
                        displayBuilder: (item) => item.name,
                      ),
                      const SizedBox(height: 16),

                      // Vaccinations
                      _buildSubSection(
                        title: 'Vaccinations',
                        list: _vaccinations,
                        addController: _vaccinationController,
                        onAdd: () {
                          final name = _vaccinationController.text.trim();
                          if (name.isNotEmpty) {
                            setState(() {
                              _vaccinations.add(
                                Vaccination(id: _tempId(), name: name),
                              );
                              _vaccinationController.clear();
                            });
                          }
                        },
                        onRemove: (index) {
                          setState(() => _vaccinations.removeAt(index));
                        },
                        displayBuilder: (item) => item.name,
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      PrimaryButton(
                        label: _isLoading ? 'Enregistrement...' : 'Enregistrer',
                        isLoading: _isLoading,
                        onPressed: _saveRecord,
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

  Widget _buildSubSection<T>({
    required String title,
    required List<T> list,
    required TextEditingController addController,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required String Function(T) displayBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.heading3),
        const SizedBox(height: 8),
        ...list.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: context.palette.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.palette.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(child: Text(displayBuilder(item))),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => onRemove(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: addController,
                decoration: InputDecoration(
                  hintText: 'Ajouter $title',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add_circle, color: context.palette.primary),
              onPressed: onAdd,
              iconSize: 32,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveRecord() async {
    final palette = context.palette;
    if (!_formKey.currentState!.validate()) return;

    final patientId = SupabaseService().currentUser?.id;
    if (patientId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    setState(() => _isLoading = true);

    final record = HealthRecord(
      id: widget.recordId ?? _tempId(),
      patientId: patientId,
      bloodType: _bloodType,
      height: _height,
      weight: _weight,
      allergies: _allergies,
      medicalConditions: _conditions,
      medications: _medications,
      vaccinations: _vaccinations,
      notes: _notes,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context.read<HealthRecordProvider>().saveRecord(
      record,
    );
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<HealthRecordProvider>().error ??
                'Erreur lors de l\'enregistrement',
          ),
          backgroundColor: palette.danger,
        ),
      );
    }
  }
}
