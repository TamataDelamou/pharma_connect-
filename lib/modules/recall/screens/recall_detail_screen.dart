import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/recall_status.dart';
import '../providers/recall_provider.dart';
import '../widgets/recall_status_chip.dart';
import '../widgets/affected_batch_tile.dart';

class RecallDetailScreen extends StatefulWidget {
  final String recallId;

  const RecallDetailScreen({super.key, required this.recallId});

  @override
  State<RecallDetailScreen> createState() => _RecallDetailScreenState();
}

class _RecallDetailScreenState extends State<RecallDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecallProvider>().loadRecall(widget.recallId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecallProvider>();
    final recall = provider.selectedRecall;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (recall == null) {
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
                      'Détail du rappel',
                      style: PharmaConnectTypography.heading2,
                    ),
                  ),
                  const KernelBadge(),
                ],
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: Center(
                  child: Text(
                    'Rappel introuvable',
                    style: PharmaConnectTypography.body2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                Expanded(
                  child: Text(
                    'Détail du rappel',
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
                    // En-tête
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${recall.severityIcon} ',
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recall.title,
                                      style: PharmaConnectTypography.heading3,
                                    ),
                                    Text(
                                      'Réf: ${recall.referenceNumber}',
                                      style: PharmaConnectTypography.body2,
                                    ),
                                  ],
                                ),
                              ),
                              RecallStatusChip(status: recall.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gravité',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      recall.severityLabel,
                                      style: TextStyle(
                                        color: recall.severityColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Émis par',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(recall.issuedBy),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date d\'émission',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(_formatDate(recall.issuedAt)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (recall.reason != null) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Motif',
                              style: PharmaConnectTypography.label,
                            ),
                            Text(recall.reason!),
                          ],
                          if (recall.correctiveAction != null) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Action corrective',
                              style: PharmaConnectTypography.label,
                            ),
                            Text(recall.correctiveAction!),
                          ],
                          if (recall.distributionInstructions != null) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Instructions de distribution',
                              style: PharmaConnectTypography.label,
                            ),
                            Text(recall.distributionInstructions!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lots affectés
                    const Text(
                      'Lots affectés',
                      style: PharmaConnectTypography.heading3,
                    ),
                    const SizedBox(height: 8),
                    if (recall.affectedBatches.isEmpty) ...[
                      const Text(
                        'Aucun lot affecté',
                        style: PharmaConnectTypography.body2,
                      ),
                    ] else ...[
                      ...recall.affectedBatches.map(
                        (batch) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AffectedBatchTile(
                            batch: batch,
                            onUpdate:
                                (
                                  newStatus,
                                  unitsReturned,
                                  unitsDestroyed,
                                ) async {
                                  await provider.updateBatchStatus(
                                    recall.id,
                                    batch.id,
                                    newStatus,
                                    unitsReturned: unitsReturned,
                                    unitsDestroyed: unitsDestroyed,
                                  );
                                },
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Statistiques du rappel
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Suivi du rappel',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Progression',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      '${(recall.completionRate * 100).toStringAsFixed(0)}%',
                                      style: PharmaConnectTypography.kpiSmall
                                          .copyWith(
                                            color: recall.completionRate > 0.8
                                                ? PharmaConnectColors
                                                      .accentGreen
                                                : PharmaConnectColors
                                                      .accentOrange,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Retournés',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text('${recall.unitsReturned ?? 0} unités'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Détruits',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      '${recall.unitsDestroyed ?? 0} unités',
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Non récupérés',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      '${recall.unitsUnrecovered ?? 0} unités',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: recall.completionRate,
                            color: recall.completionRate > 0.8
                                ? PharmaConnectColors.accentGreen
                                : PharmaConnectColors.accentOrange,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Checklist de conformité
                    _buildChecklist(recall),

                    const SizedBox(height: 16),

                    // Actions
                    if (recall.isEditable) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Publier le rappel',
                              icon: Icons.send,
                              onPressed: () async {
                                final success = await provider.publishRecall(
                                  recall.id,
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Rappel publié avec succès',
                                      ),
                                      backgroundColor:
                                          PharmaConnectColors.accentGreen,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Annuler',
                              icon: Icons.cancel,
                              onPressed: () {
                                _showCancelDialog(context, recall);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (recall.isActive) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Terminer le rappel',
                              icon: Icons.check_circle,
                              onPressed: () async {
                                final success = await provider.completeRecall(
                                  recall.id,
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Rappel terminé'),
                                      backgroundColor:
                                          PharmaConnectColors.accentGreen,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklist(recall) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Checklist de conformité',
            style: PharmaConnectTypography.heading3,
          ),
          const SizedBox(height: 8),
          _buildCheckItem('📤 Notification envoyée', recall.issuedAt != null),
          _buildCheckItem('📦 Lots retournés', (recall.unitsReturned ?? 0) > 0),
          _buildCheckItem('💀 Lots détruits', (recall.unitsDestroyed ?? 0) > 0),
          _buildCheckItem(
            '📝 Rapport final',
            recall.status == RecallStatus.completed,
          ),
          if (recall.status == RecallStatus.completed) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PharmaConnectColors.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PharmaConnectColors.accentGreen.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: PharmaConnectColors.accentGreen,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tous les éléments sont conformes',
                    style: TextStyle(
                      color: PharmaConnectColors.accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.circle_outlined,
            color: isChecked
                ? PharmaConnectColors.accentGreen
                : PharmaConnectColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isChecked
                    ? PharmaConnectColors.textPrimary
                    : PharmaConnectColors.textSecondary,
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isChecked) ...[const Text('✅', style: TextStyle(fontSize: 16))],
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, recall) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Annuler le rappel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir annuler ce rappel ?',
              style: PharmaConnectTypography.body1,
            ),
            const SizedBox(height: 8),
            Text(
              'Cette action est irréversible.',
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<RecallProvider>().cancelRecall(
                recall.id,
                reason: 'Annulé par l\'utilisateur',
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rappel annulé'),
                    backgroundColor: PharmaConnectColors.accentRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentRed,
              foregroundColor: PharmaConnectColors.textPrimary,
            ),
            child: const Text('Confirmer l\'annulation'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
