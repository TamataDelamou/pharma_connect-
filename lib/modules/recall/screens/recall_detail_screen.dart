import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/recall_status.dart';
import '../providers/recall_provider.dart';
import '../widgets/recall_status_chip.dart';
import '../widgets/affected_batch_tile.dart';
import '../../../core/theme/palette.dart';

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
                        'Détail du rappel',
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
                child: Center(
                  child: Text('Rappel introuvable', style: context.text.body2),
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: context.palette.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Détail du rappel', style: context.text.heading2),
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
                                      style: context.text.heading3,
                                    ),
                                    Text(
                                      'Réf: ${recall.referenceNumber}',
                                      style: context.text.body2,
                                    ),
                                  ],
                                ),
                              ),
                              RecallStatusChip(status: recall.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(color: context.palette.veil(0.12)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Gravité', style: context.text.label),
                                    Text(
                                      recall.severityLabel,
                                      style: TextStyle(
                                        color: recall.severityColor.of(
                                          context.palette,
                                        ),
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
                                    Text('Émis par', style: context.text.label),
                                    Text(recall.issuedBy),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date d\'émission',
                                      style: context.text.label,
                                    ),
                                    Text(_formatDate(recall.issuedAt)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (recall.reason != null) ...[
                            const SizedBox(height: 8),
                            Text('Motif', style: context.text.label),
                            Text(recall.reason!),
                          ],
                          if (recall.correctiveAction != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Action corrective',
                              style: context.text.label,
                            ),
                            Text(recall.correctiveAction!),
                          ],
                          if (recall.distributionInstructions != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Instructions de distribution',
                              style: context.text.label,
                            ),
                            Text(recall.distributionInstructions!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lots affectés
                    Text('Lots affectés', style: context.text.heading3),
                    const SizedBox(height: 8),
                    if (recall.affectedBatches.isEmpty) ...[
                      Text('Aucun lot affecté', style: context.text.body2),
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
                          Text('Suivi du rappel', style: context.text.heading3),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Progression',
                                      style: context.text.label,
                                    ),
                                    Text(
                                      '${(recall.completionRate * 100).toStringAsFixed(0)}%',
                                      style: context.text.kpiSmall.copyWith(
                                        color: recall.completionRate > 0.8
                                            ? PharmaConnectColors.accentGreen
                                            : PharmaConnectColors.accentOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Retournés',
                                      style: context.text.label,
                                    ),
                                    Text('${recall.unitsReturned ?? 0} unités'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Détruits', style: context.text.label),
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
                                    Text(
                                      'Non récupérés',
                                      style: context.text.label,
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
                                ? context.palette.success
                                : context.palette.warning,
                            backgroundColor: context.palette.border,
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
                                    SnackBar(
                                      content: Text(
                                        'Rappel publié avec succès',
                                      ),
                                      backgroundColor: context.palette.success,
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
                                    SnackBar(
                                      content: Text('Rappel terminé'),
                                      backgroundColor: context.palette.success,
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
          Text('Checklist de conformité', style: context.text.heading3),
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
                color: context.palette.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.palette.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: context.palette.success),
                  SizedBox(width: 8),
                  Text(
                    'Tous les éléments sont conformes',
                    style: TextStyle(
                      color: context.palette.success,
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
                ? context.palette.success
                : context.palette.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isChecked
                    ? context.palette.textPrimary
                    : context.palette.textSecondary,
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
        backgroundColor: context.palette.background,
        title: const Text('Annuler le rappel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Êtes-vous sûr de vouloir annuler ce rappel ?',
              style: context.text.body1,
            ),
            const SizedBox(height: 8),
            Text(
              'Cette action est irréversible.',
              style: context.text.body2.copyWith(color: context.palette.danger),
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
                  SnackBar(
                    content: Text('Rappel annulé'),
                    backgroundColor: context.palette.danger,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.textPrimary,
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
