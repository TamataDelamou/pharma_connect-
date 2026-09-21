import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/regulator_provider.dart';

class AdverseReactionDetailScreen extends StatefulWidget {
  final String reactionId;

  const AdverseReactionDetailScreen({super.key, required this.reactionId});

  @override
  State<AdverseReactionDetailScreen> createState() =>
      _AdverseReactionDetailScreenState();
}

class _AdverseReactionDetailScreenState
    extends State<AdverseReactionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegulatorProvider>().loadReaction(widget.reactionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegulatorProvider>();
    final reaction = provider.selectedReaction;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (reaction == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Signalement introuvable',
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        ),
      );
    }

    // Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-2/REG-3 : l'ancien
    // calcul `reaction.reporterId != SupabaseService().currentUser?.id`
    // référençait un identifiant non importé (défaut de compilation, REG-2)
    // et n'était de toute façon qu'un proxy ("je ne suis pas l'auteur") sans
    // rapport avec un vrai rôle de gestion (motif "miroir client" déjà
    // rencontré en CHN-6/PRE-6). Remplacé par le rôle staff GSG réel,
    // cohérent avec la policy RLS `is_gsg_admin()` posée en Étape 2 : ce
    // booléen ne sert qu'à proposer les actions à l'écran, RLS reste le
    // seul rempart réel côté serveur.
    final canManage = context.watch<AuthProvider>().isGsgAdmin;

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
                    'Signalement d\'effet indésirable',
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
                    GlassCard(
                      glow: true,
                      glowColor: _severityColor(reaction.severity),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _severityColor(reaction.severity),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      reaction.medicationName,
                                      style: PharmaConnectTypography.heading3,
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _severityColor(
                                          reaction.severity,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        reaction.severityLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _severityColor(
                                            reaction.severity,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Signalé le ${_formatDate(reaction.reportedAt)}',
                                  style: PharmaConnectTypography.body2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Médicament', reaction.medicationName),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Date de la réaction',
                            _formatDate(reaction.reactionDate),
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow('Symptômes', reaction.symptoms),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Signalé par',
                            reaction.reporterName ?? reaction.reporterId,
                          ),
                          if (reaction.patientName != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Patient', reaction.patientName!),
                          ],
                          if (reaction.outcome != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Évolution', reaction.outcome!),
                          ],
                          if (reaction.notes != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Notes', reaction.notes!),
                          ],
                          if (reaction.followUpNotes != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Suivi', reaction.followUpNotes!),
                          ],
                          if (reaction.regulatoryAction != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Action réglementaire',
                              reaction.regulatoryAction!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status actions (only for GSG staff managing the case)
                    if (canManage && reaction.status != 'closed') ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gestion du signalement',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (reaction.status == 'pending') ...[
                                  _buildActionChip(
                                    'Prendre en charge',
                                    'under_review',
                                    PharmaConnectColors.accentCyan,
                                  ),
                                ],
                                if (reaction.status == 'under_review') ...[
                                  _buildActionChip(
                                    'En investigation',
                                    'investigating',
                                    PharmaConnectColors.accentOrange,
                                  ),
                                ],
                                if (reaction.status == 'under_review' ||
                                    reaction.status == 'investigating') ...[
                                  _buildActionChip(
                                    'Clore',
                                    'closed',
                                    PharmaConnectColors.accentGreen,
                                  ),
                                  _buildActionChip(
                                    'Rejeter',
                                    'rejected',
                                    PharmaConnectColors.accentRed,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (reaction.status == 'closed' ||
                        reaction.status == 'rejected') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: reaction.status == 'closed'
                              ? PharmaConnectColors.accentGreen.withValues(
                                  alpha: 0.1,
                                )
                              : PharmaConnectColors.accentRed.withValues(
                                  alpha: 0.1,
                                ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: reaction.status == 'closed'
                                ? PharmaConnectColors.accentGreen.withValues(
                                    alpha: 0.2,
                                  )
                                : PharmaConnectColors.accentRed.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              reaction.status == 'closed'
                                  ? Icons.check_circle
                                  : Icons.block,
                              color: reaction.status == 'closed'
                                  ? PharmaConnectColors.accentGreen
                                  : PharmaConnectColors.accentRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Signalement ${reaction.status == 'closed' ? 'clos' : 'rejeté'}',
                                style: TextStyle(
                                  color: reaction.status == 'closed'
                                      ? PharmaConnectColors.accentGreen
                                      : PharmaConnectColors.accentRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Suppression réservée au staff GSG (motif miroir client,
                    // cf. commentaire ci-dessus) — RLS (is_gsg_admin())
                    // bloquait déjà l'appel pour tout autre compte, mais
                    // afficher le bouton à un déclarant/patient qui verrait
                    // ensuite l'action échouer silencieusement est une
                    // mauvaise expérience ; on aligne l'UI sur le vrai rôle.
                    if (canManage) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, reaction.id),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PharmaConnectColors.accentRed,
                          side: const BorderSide(
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: PharmaConnectTypography.label),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body1)),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, String status, Color color) {
    return GestureDetector(
      onTap: () async {
        final updated = context.read<RegulatorProvider>().selectedReaction;
        if (updated != null) {
          final updatedReaction = updated.copyWith(status: status);
          final success = await context.read<RegulatorProvider>().saveReaction(
            updatedReaction,
          );
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Statut mis à jour : $label')),
            );
            context.read<RegulatorProvider>().loadReaction(widget.reactionId);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'mild':
        return PharmaConnectColors.accentCyan;
      case 'moderate':
        return PharmaConnectColors.accentOrange;
      case 'severe':
        return PharmaConnectColors.accentRed;
      case 'life_threatening':
        return PharmaConnectColors.accentRed;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Supprimer'),
        content: const Text('Supprimer ce signalement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<RegulatorProvider>()
                  .deleteReaction(id);
              if (success && context.mounted) context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentRed,
              foregroundColor: PharmaConnectColors.textPrimary,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
