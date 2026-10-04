import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../providers/preventive_alert_provider.dart';
import '../models/preventive_alert.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class PreventiveAlertCreateScreen extends StatefulWidget {
  final String? alertId;

  const PreventiveAlertCreateScreen({super.key, this.alertId});

  @override
  State<PreventiveAlertCreateScreen> createState() =>
      _PreventiveAlertCreateScreenState();
}

class _PreventiveAlertCreateScreenState
    extends State<PreventiveAlertCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _daysController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedType = 'vaccination';
  String _selectedKey = 'vaccination';
  bool _isLoading = false;

  final List<Map<String, String>> _alertTypes = const [
    {'value': 'vaccination', 'label': '💉 Vaccination'},
    {'value': 'screening', 'label': '🔬 Dépistage'},
    {'value': 'medication_refill', 'label': '💊 Renouvellement'},
    {'value': 'checkup', 'label': '🩺 Bilan de santé'},
    {'value': 'lifestyle', 'label': '🧘 Mode de vie'},
  ];

  final List<Map<String, String>> _keys = const [
    {'value': 'vaccination', 'label': 'Dernière vaccination'},
    {'value': 'consultation', 'label': 'Dernière consultation'},
    {'value': 'prescription', 'label': 'Dernière prescription'},
    {'value': 'checkup', 'label': 'Dernier bilan'},
  ];

  @override
  void dispose() {
    _daysController.dispose();
    _messageController.dispose();
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
                      widget.alertId == null
                          ? '🔔 Nouvelle alerte préventive'
                          : '🔔 Modifier l\'alerte',
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
                            // Alert type
                            DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Type d\'alerte',
                                border: OutlineInputBorder(),
                              ),
                              items: _alertTypes.map((type) {
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

                            // Key selection
                            DropdownButtonFormField<String>(
                              value: _selectedKey,
                              decoration: const InputDecoration(
                                labelText: 'Événement à surveiller',
                                border: OutlineInputBorder(),
                              ),
                              items: _keys.map((key) {
                                return DropdownMenuItem<String>(
                                  value: key['value'],
                                  child: Text(key['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null)
                                  setState(() => _selectedKey = value);
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Délai (jours)',
                              hint: 'Ex: 365',
                              controller: _daysController,
                              prefixIcon: Icons.calendar_today,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un délai';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Nombre invalide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Message de l\'alerte',
                              hint:
                                  'Ex: Il est temps de faire votre rappel de vaccination',
                              controller: _messageController,
                              prefixIcon: Icons.message,
                              keyboardType: TextInputType.multiline,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un message';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.palette.primary.withValues(
                            alpha: 0.06,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.palette.primary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: context.palette.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vous recevrez une notification lorsque le délai sera dépassé depuis le dernier événement.',
                                style: context.text.micro.copyWith(
                                  color: context.palette.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: _isLoading
                            ? widget.alertId == null
                                  ? 'Création...'
                                  : 'Mise à jour...'
                            : widget.alertId == null
                            ? 'Créer l\'alerte'
                            : 'Mettre à jour',
                        isLoading: _isLoading,
                        onPressed: _saveAlert,
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

  Future<void> _saveAlert() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = SupabaseService().currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    final days = int.parse(_daysController.text.trim());

    setState(() => _isLoading = true);

    final alert = PreventiveAlert(
      id: widget.alertId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      patientId: userId,
      alertType: _selectedType,
      triggerCondition: {'days_since': days, 'key': _selectedKey},
      messageTemplate: _messageController.text.trim(),
      isActive: true,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context.read<PreventiveAlertProvider>().saveAlert(
      alert,
    );
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.alertId == null
                ? 'Alerte créée avec succès'
                : 'Alerte mise à jour',
          ),
          backgroundColor: context.palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<PreventiveAlertProvider>().error ?? 'Erreur',
          ),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }
}
