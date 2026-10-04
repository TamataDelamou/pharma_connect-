import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../providers/health_goal_provider.dart';
import '../models/health_goal.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class HealthGoalCreateScreen extends StatefulWidget {
  final String? goalId;

  const HealthGoalCreateScreen({super.key, this.goalId});

  @override
  State<HealthGoalCreateScreen> createState() => _HealthGoalCreateScreenState();
}

class _HealthGoalCreateScreenState extends State<HealthGoalCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();

  String _selectedType = 'steps';
  String _selectedPeriod = 'daily';

  bool _isLoading = false;

  final List<Map<String, String>> _goalTypes = const [
    {'value': 'steps', 'label': '🚶 Pas'},
    {'value': 'water', 'label': '💧 Eau (litres)'},
    {'value': 'fruits', 'label': '🍎 Fruits (portions)'},
    {'value': 'meditation', 'label': '🧘 Méditation (minutes)'},
    {'value': 'sleep', 'label': '😴 Sommeil (heures)'},
  ];

  final List<Map<String, String>> _periods = const [
    {'value': 'daily', 'label': 'Quotidien'},
    {'value': 'weekly', 'label': 'Hebdomadaire'},
    {'value': 'monthly', 'label': 'Mensuel'},
  ];

  @override
  void dispose() {
    _targetController.dispose();
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
                      widget.goalId == null
                          ? '🎯 Nouvel objectif'
                          : '🎯 Modifier l\'objectif',
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
                            // Goal type
                            DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Type d\'objectif',
                                border: OutlineInputBorder(),
                              ),
                              items: _goalTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type['value'],
                                  child: Text(type['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null)
                                  setState(() => _selectedType = value);
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Objectif',
                              hint: 'Ex: 10000, 1.5, 30',
                              controller: _targetController,
                              prefixIcon: Icons.flag,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un objectif';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Nombre invalide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Period
                            DropdownButtonFormField<String>(
                              value: _selectedPeriod,
                              decoration: const InputDecoration(
                                labelText: 'Période',
                                border: OutlineInputBorder(),
                              ),
                              items: _periods.map((period) {
                                return DropdownMenuItem<String>(
                                  value: period['value'],
                                  child: Text(period['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null)
                                  setState(() => _selectedPeriod = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: _isLoading
                            ? widget.goalId == null
                                  ? 'Création...'
                                  : 'Mise à jour...'
                            : widget.goalId == null
                            ? 'Créer l\'objectif'
                            : 'Mettre à jour',
                        isLoading: _isLoading,
                        onPressed: _saveGoal,
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

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = SupabaseService().currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    final target = double.parse(_targetController.text.trim());

    setState(() => _isLoading = true);

    final goal = HealthGoal(
      id: widget.goalId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      patientId: userId,
      goalType: _selectedType,
      targetValue: target,
      currentValue: 0,
      period: _selectedPeriod,
      startDate: DateTime.now(),
      status: 'active',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context.read<HealthGoalProvider>().saveGoal(goal);
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.goalId == null
                ? 'Objectif créé avec succès'
                : 'Objectif mis à jour',
          ),
          backgroundColor: context.palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<HealthGoalProvider>().error ?? 'Erreur'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }
}
