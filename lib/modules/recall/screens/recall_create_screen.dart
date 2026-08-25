import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/recall_provider.dart';
import '../models/recall_severity.dart';
import '../models/recall_affected_batch.dart';
import '../models/batch_recall_status.dart';

class RecallCreateScreen extends StatefulWidget {
  const RecallCreateScreen({super.key});

  @override
  State<RecallCreateScreen> createState() => _RecallCreateScreenState();
}

class _RecallCreateScreenState extends State<RecallCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reasonController = TextEditingController();
  final _correctiveActionController = TextEditingController();
  final _issuedByController = TextEditingController();
  RecallSeverity _selectedSeverity = RecallSeverity.classII;
  bool _isPublic = true;
  List<RecallAffectedBatch> _affectedBatches = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reasonController.dispose();
    _correctiveActionController.dispose();
    _issuedByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecallProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
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
                    'Nouveau rappel',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez un rappel de lot pour une alerte de sécurité ou un défaut de fabrication',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations générales',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 16),

                          GlassInput(
                            label: 'Titre du rappel *',
                            hint: 'Ex: Rappel lot X - Défaut de fabrication',
                            controller: _titleController,
                            prefixIcon: Icons.warning,
                          ),
                          const SizedBox(height: 12),

                          GlassInput(
                            label: 'Description *',
                            hint: 'Description détaillée du rappel',
                            controller: _descriptionController,
                            prefixIcon: Icons.description,
                          ),
                          const SizedBox(height: 12),

                          GlassInput(
                            label: 'Motif du rappel',
                            hint:
                                'Raison du rappel (ex: défaut de fabrication, étiquetage...)',
                            controller: _reasonController,
                            prefixIcon: Icons.report,
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            'Gravité du rappel *',
                            style: PharmaConnectTypography.label,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: RecallSeverity.values.map((severity) {
                              return ChoiceChip(
                                label: Text(severity.label),
                                selected: _selectedSeverity == severity,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(
                                      () => _selectedSeverity = severity,
                                    );
                                  }
                                },
                                selectedColor: severity == RecallSeverity.classI
                                    ? PharmaConnectColors.accentRed.withValues(
                                        alpha: 0.2,
                                      )
                                    : severity == RecallSeverity.classII
                                    ? PharmaConnectColors.accentOrange
                                          .withValues(alpha: 0.2)
                                    : PharmaConnectColors.accentCyan.withValues(
                                        alpha: 0.2,
                                      ),
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color: _selectedSeverity == severity
                                      ? severity == RecallSeverity.classI
                                            ? PharmaConnectColors.accentRed
                                            : severity == RecallSeverity.classII
                                            ? PharmaConnectColors.accentOrange
                                            : PharmaConnectColors.accentCyan
                                      : Colors.white24,
                                ),
                                labelStyle: TextStyle(
                                  color: _selectedSeverity == severity
                                      ? severity == RecallSeverity.classI
                                            ? PharmaConnectColors.accentRed
                                            : severity == RecallSeverity.classII
                                            ? PharmaConnectColors.accentOrange
                                            : PharmaConnectColors.accentCyan
                                      : Colors.white70,
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),

                          GlassInput(
                            label: 'Émis par *',
                            hint: 'Ex: DNPM, Sanofi, Pharmacie Centrale...',
                            controller: _issuedByController,
                            prefixIcon: Icons.business,
                          ),
                          const SizedBox(height: 12),

                          GlassInput(
                            label: 'Action corrective',
                            hint:
                                'Actions à réaliser pour corriger le problème',
                            controller: _correctiveActionController,
                            prefixIcon: Icons.build,
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Checkbox(
                                value: _isPublic,
                                onChanged: (value) {
                                  setState(() => _isPublic = value ?? true);
                                },
                                activeColor: PharmaConnectColors.accentCyan,
                              ),
                              const Text(
                                'Rappel public',
                                style: PharmaConnectTypography.body1,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lots affectés
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Lots affectés',
                                style: PharmaConnectTypography.heading3,
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: PharmaConnectColors.accentCyan,
                                ),
                                onPressed: () => _showAddBatchDialog(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_affectedBatches.isEmpty) ...[
                            const Text(
                              'Aucun lot ajouté',
                              style: PharmaConnectTypography.body2,
                            ),
                          ] else ...[
                            ..._affectedBatches.map(
                              (batch) => Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            batch.productName,
                                            style: PharmaConnectTypography.body1
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            'Lot: ${batch.batchNumber} • ${batch.totalUnits} unités',
                                            style:
                                                PharmaConnectTypography.body2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: PharmaConnectColors.accentRed,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _affectedBatches.remove(batch);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Annuler',
                            onPressed: () => context.pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            label: 'Créer le rappel',
                            isLoading: _isSubmitting || provider.isLoading,
                            onPressed: _affectedBatches.isEmpty
                                ? null
                                : () async {
                                    if (_titleController.text.trim().isEmpty ||
                                        _descriptionController.text
                                            .trim()
                                            .isEmpty ||
                                        _issuedByController.text
                                            .trim()
                                            .isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Veuillez remplir tous les champs obligatoires',
                                          ),
                                          backgroundColor:
                                              PharmaConnectColors.accentRed,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => _isSubmitting = true);
                                    final recall = await provider.createRecall(
                                      title: _titleController.text.trim(),
                                      description: _descriptionController.text
                                          .trim(),
                                      severity: _selectedSeverity,
                                      issuedBy: _issuedByController.text.trim(),
                                      affectedBatches: _affectedBatches,
                                      reason: _reasonController.text.trim(),
                                      correctiveAction:
                                          _correctiveActionController.text
                                              .trim(),
                                      isPublic: _isPublic,
                                    );
                                    setState(() => _isSubmitting = false);

                                    if (recall != null && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Rappel créé avec succès',
                                          ),
                                          backgroundColor:
                                              PharmaConnectColors.accentGreen,
                                        ),
                                      );
                                      context.go('/recall/${recall.id}');
                                    }
                                  },
                          ),
                        ),
                      ],
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

  void _showAddBatchDialog(BuildContext context) {
    final batchNumberController = TextEditingController();
    final productNameController = TextEditingController();
    final unitsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Ajouter un lot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassInput(
              label: 'Numéro de lot *',
              hint: 'Ex: DOL-2024-001',
              controller: batchNumberController,
              prefixIcon: Icons.qr_code,
            ),
            const SizedBox(height: 8),
            GlassInput(
              label: 'Nom du produit *',
              hint: 'Ex: Doliprane 1000mg',
              controller: productNameController,
              prefixIcon: Icons.medication,
            ),
            const SizedBox(height: 8),
            GlassInput(
              label: 'Nombre d\'unités *',
              hint: 'Ex: 1000',
              controller: unitsController,
              prefixIcon: Icons.numbers,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final batchNumber = batchNumberController.text.trim();
              final productName = productNameController.text.trim();
              final units = int.tryParse(unitsController.text.trim());

              if (batchNumber.isEmpty ||
                  productName.isEmpty ||
                  units == null ||
                  units <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Veuillez remplir tous les champs correctement',
                    ),
                    backgroundColor: PharmaConnectColors.accentRed,
                  ),
                );
                return;
              }

              setState(() {
                _affectedBatches.add(
                  RecallAffectedBatch(
                    id: 'rab_${DateTime.now().millisecondsSinceEpoch}',
                    recallId: '',
                    batchId: 'tb_${DateTime.now().millisecondsSinceEpoch}',
                    batchNumber: batchNumber,
                    productName: productName,
                    productId: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                    totalUnits: units,
                    unitsRecalled: units,
                    unitsReturned: 0,
                    unitsDestroyed: 0,
                    status: BatchRecallStatus.pending,
                  ),
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
