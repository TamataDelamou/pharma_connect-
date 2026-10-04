import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../models/regulatory_inspection.dart';
import '../providers/inspection_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4.
//
// Limitation connue (motif déjà documenté ailleurs dans l'audit pour des
// besoins similaires, cf. registre des écarts) : `regulatory_inspections`
// utilise `entity_id` comme référence polymorphe (officine, hôpital,
// laboratoire, fabricant, grossiste selon `entity_type`), sans clé
// étrangère unique et sans sélecteur d'entité réutilisable dans ce
// module. En l'absence d'un tel composant, l'identifiant est saisi
// manuellement ici — limitation fonctionnelle assumée et non une faille
// de sécurité, RLS ne dépendant pas de ce champ.
class InspectionCreateScreen extends StatefulWidget {
  const InspectionCreateScreen({super.key});

  @override
  State<InspectionCreateScreen> createState() => _InspectionCreateScreenState();
}

class _InspectionCreateScreenState extends State<InspectionCreateScreen> {
  final _entityIdController = TextEditingController();
  String? _entityType;
  String? _type;
  DateTime? _inspectionDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _entityIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
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
                      'Planifier une inspection',
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
                          DropdownButtonFormField<String>(
                            value: _entityType,
                            decoration: const InputDecoration(
                              labelText: 'Type d\'entité',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pharmacy',
                                child: Text('Officine'),
                              ),
                              DropdownMenuItem(
                                value: 'hospital',
                                child: Text('Hôpital'),
                              ),
                              DropdownMenuItem(
                                value: 'laboratory',
                                child: Text('Laboratoire'),
                              ),
                              DropdownMenuItem(
                                value: 'manufacturer',
                                child: Text('Fabricant'),
                              ),
                              DropdownMenuItem(
                                value: 'wholesaler',
                                child: Text('Grossiste'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _entityType = v),
                          ),
                          const SizedBox(height: 12),
                          GlassInput(
                            label: 'Identifiant de l\'entité (UUID)',
                            hint: 'Saisie manuelle — voir limitation ci-dessus',
                            controller: _entityIdController,
                            prefixIcon: Icons.tag,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _type,
                            decoration: const InputDecoration(
                              labelText: 'Type d\'inspection',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'routine',
                                child: Text('Routine'),
                              ),
                              DropdownMenuItem(
                                value: 'complaint',
                                child: Text('Plainte'),
                              ),
                              DropdownMenuItem(
                                value: 'follow_up',
                                child: Text('Suivi'),
                              ),
                              DropdownMenuItem(
                                value: 'emergency',
                                child: Text('Urgence'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _type = v),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            title: const Text('Date d\'inspection'),
                            subtitle: Text(
                              _inspectionDate != null
                                  ? _formatDate(_inspectionDate!)
                                  : 'Sélectionnez une date',
                            ),
                            leading: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() => _inspectionDate = date);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isLoading ? 'Envoi...' : 'Planifier',
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
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Future<void> _submit() async {
    final palette = context.palette;
    if (_entityType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer le type d\'entité')),
      );
      return;
    }
    final entityId = _entityIdController.text.trim();
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (entityId.isEmpty || !uuidPattern.hasMatch(entityId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifiant d\'entité invalide (format UUID attendu)'),
        ),
      );
      return;
    }
    if (_type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer le type d\'inspection'),
        ),
      );
      return;
    }
    if (_inspectionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now().toUtc();
    final inspection = RegulatoryInspection(
      id: 'temp_${now.millisecondsSinceEpoch}',
      entityType: _entityType!,
      entityId: entityId,
      inspectionDate: _inspectionDate!,
      type: _type!,
      status: 'scheduled',
      createdAt: now,
      updatedAt: now,
    );

    final success = await context.read<InspectionProvider>().saveInspection(
      inspection,
    );
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inspection planifiée'),
          backgroundColor: palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<InspectionProvider>().error ??
                'Erreur lors de l\'envoi',
          ),
          backgroundColor: palette.danger,
        ),
      );
    }
  }
}
