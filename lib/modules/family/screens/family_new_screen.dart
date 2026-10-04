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
import '../providers/family_provider.dart';
import '../models/family_link.dart';
import '../models/family_link_status.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class FamilyNewScreen extends StatefulWidget {
  const FamilyNewScreen({super.key});

  @override
  State<FamilyNewScreen> createState() => _FamilyNewScreenState();
}

class _FamilyNewScreenState extends State<FamilyNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyMemberIdController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _notesController = TextEditingController();

  bool _canViewRecords = true;
  bool _canViewPrescriptions = true;
  bool _canBookConsultations = false;
  bool _canReceiveAlerts = true;

  bool _isLoading = false;

  @override
  void dispose() {
    _familyMemberIdController.dispose();
    _relationshipController.dispose();
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
                        'Ajouter un lien familial',
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
                              label: 'ID du membre de la famille',
                              hint: 'Entrez l\'ID de la personne à ajouter',
                              controller: _familyMemberIdController,
                              prefixIcon: Icons.person_add,
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Relation',
                              hint: 'ex: parent, enfant, conjoint, frère/soeur',
                              controller: _relationshipController,
                              prefixIcon: Icons.family_restroom,
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
                      const SizedBox(height: 16),

                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Permissions', style: context.text.heading3),
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              value: _canViewRecords,
                              onChanged: (v) =>
                                  setState(() => _canViewRecords = v ?? true),
                              title: const Text('Voir les dossiers de santé'),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              value: _canViewPrescriptions,
                              onChanged: (v) => setState(
                                () => _canViewPrescriptions = v ?? true,
                              ),
                              title: const Text('Voir les ordonnances'),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              value: _canBookConsultations,
                              onChanged: (v) => setState(
                                () => _canBookConsultations = v ?? false,
                              ),
                              title: const Text('Prendre des rendez-vous'),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              value: _canReceiveAlerts,
                              onChanged: (v) =>
                                  setState(() => _canReceiveAlerts = v ?? true),
                              title: const Text('Recevoir des alertes'),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: _isLoading ? 'Envoi...' : 'Inviter',
                        isLoading: _isLoading,
                        onPressed: _submitLink,
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

  Future<void> _submitLink() async {
    final palette = context.palette;
    if (!_formKey.currentState!.validate()) return;

    if (_familyMemberIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer l\'ID du membre de la famille'),
        ),
      );
      return;
    }

    final patientId = SupabaseService().currentUser?.id;
    if (patientId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    // Don't allow adding yourself
    if (_familyMemberIdController.text.trim() == patientId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas vous ajouter vous-même'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final link = FamilyLink(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      familyMemberId: _familyMemberIdController.text.trim(),
      relationship: _relationshipController.text.trim(),
      canViewRecords: _canViewRecords,
      canViewPrescriptions: _canViewPrescriptions,
      canBookConsultations: _canBookConsultations,
      canReceiveAlerts: _canReceiveAlerts,
      status: FamilyLinkStatus.pending,
      invitedAt: DateTime.now().toUtc(),
      notes: _notesController.text.trim(),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context.read<FamilyProvider>().createLink(link);
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation envoyée !'),
          backgroundColor: palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<FamilyProvider>().error ?? 'Erreur'),
          backgroundColor: palette.danger,
        ),
      );
    }
  }
}
