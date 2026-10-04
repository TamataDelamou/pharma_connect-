import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/homecare_provider.dart';
import '../models/homecare_status.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class HomecareDetailScreen extends StatefulWidget {
  final String interventionId;

  const HomecareDetailScreen({super.key, required this.interventionId});

  @override
  State<HomecareDetailScreen> createState() => _HomecareDetailScreenState();
}

class _HomecareDetailScreenState extends State<HomecareDetailScreen> {
  final _reportController = TextEditingController();
  final _feedbackController = TextEditingController();
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomecareProvider>().loadIntervention(widget.interventionId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final intervention = context.watch<HomecareProvider>().selectedIntervention;
    if (intervention != null) {
      _reportController.text = intervention.report ?? '';
      _feedbackController.text = intervention.patientFeedback ?? '';
      _rating = intervention.patientRating ?? 0;
    }
  }

  @override
  void dispose() {
    _reportController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomecareProvider>();
    final intervention = provider.selectedIntervention;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (intervention == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Intervention introuvable',
            style: context.text.body2.copyWith(color: context.palette.danger),
          ),
        ),
      );
    }

    final isProfessional =
        intervention.professionalId == SupabaseService().currentUser?.id;
    final isPatient =
        intervention.patientId == SupabaseService().currentUser?.id;

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
                      'Détail de l\'intervention',
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
                      glow: true,
                      glowColor: _statusColor(intervention.status),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _statusColor(intervention.status),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Statut : ${intervention.status.label}',
                                  style: context.text.heading3,
                                ),
                                Text(
                                  _formatDate(intervention.scheduledAt),
                                  style: context.text.body2,
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
                          _buildInfoRow(
                            'Patient',
                            intervention.patientName ?? intervention.patientId,
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow(
                            'Professionnel',
                            intervention.professionalName ??
                                intervention.professionalId,
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow('Adresse', intervention.address),
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow('Motif', intervention.reason),
                          if (intervention.durationMinutes > 0) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Durée',
                              '${intervention.durationMinutes} min',
                            ),
                          ],
                          if (intervention.startedAt != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Débuté le',
                              _formatDate(intervention.startedAt!),
                            ),
                          ],
                          if (intervention.completedAt != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Terminé le',
                              _formatDate(intervention.completedAt!),
                            ),
                          ],
                          if (intervention.notes != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow('Notes', intervention.notes!),
                          ],
                          if (intervention.refusalReason != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Motif du refus',
                              intervention.refusalReason!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Report (only for professionals)
                    if (isProfessional &&
                        intervention.status == HomecareStatus.inProgress) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compte-rendu de la visite',
                              style: context.text.heading3,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _reportController,
                              decoration: const InputDecoration(
                                hintText: 'Rédigez votre compte-rendu',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Terminer l\'intervention',
                              // Audit Module 18 (HOM, 30/08/2026), RG-HOM-03
                              // (Standard) : « Une intervention à domicile ne
                              // peut être close sans compte-rendu structuré
                              // minimal. » Avant correctif, ce bouton
                              // acceptait un compte-rendu vide sans aucune
                              // validation. Garde côté UI ajoutée ici, en
                              // plus du garde-fou service (voir
                              // `HomecareService.updateInterventionStatus`).
                              onPressed: () async {
                                if (_reportController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Un compte-rendu est obligatoire pour terminer l\'intervention (RG-HOM-03)',
                                      ),
                                      backgroundColor: context.palette.danger,
                                    ),
                                  );
                                  return;
                                }
                                final success = await provider
                                    .updateInterventionStatus(
                                      intervention.id,
                                      HomecareStatus.completed,
                                      report: _reportController.text.trim(),
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Intervention terminée'),
                                      backgroundColor: context.palette.success,
                                    ),
                                  );
                                  provider.loadIntervention(intervention.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Feedback (for patient after completion)
                    if (isPatient &&
                        intervention.status == HomecareStatus.completed &&
                        intervention.patientFeedback == null) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Évaluez l\'intervention',
                              style: context.text.heading3,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (index) {
                                return IconButton(
                                  icon: Icon(
                                    index < _rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: context.palette.warningStrong,
                                  ),
                                  onPressed: () =>
                                      setState(() => _rating = index + 1),
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _feedbackController,
                              decoration: const InputDecoration(
                                hintText: 'Votre feedback',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Envoyer le feedback',
                              onPressed: () async {
                                final success = await provider
                                    .updateInterventionStatus(
                                      intervention.id,
                                      intervention.status,
                                      patientRating: _rating,
                                      patientFeedback: _feedbackController.text
                                          .trim(),
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Merci pour votre évaluation',
                                      ),
                                      backgroundColor: context.palette.success,
                                    ),
                                  );
                                  provider.loadIntervention(intervention.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Actions
                    if (intervention.status == HomecareStatus.pending) ...[
                      if (isProfessional) ...[
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'Confirmer',
                                icon: Icons.check_circle,
                                onPressed: () async {
                                  final success = await provider
                                      .updateInterventionStatus(
                                        intervention.id,
                                        HomecareStatus.confirmed,
                                      );
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Intervention confirmée'),
                                        backgroundColor:
                                            context.palette.success,
                                      ),
                                    );
                                    provider.loadIntervention(intervention.id);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SecondaryButton(
                                label: 'Refuser',
                                icon: Icons.close,
                                // Audit Module 18 (HOM, 30/08/2026) : le
                                // cahier exige un « motif obligatoire en cas
                                // de refus » (fonctionnalité clé HOM) —
                                // absent avant correctif, le refus
                                // annulait directement l'intervention sans
                                // aucune saisie. `_showRefusalDialog` exige
                                // désormais un motif non vide.
                                onPressed: () => _showRefusalDialog(
                                  context,
                                  provider,
                                  intervention.id,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (isPatient) ...[
                        SecondaryButton(
                          label: 'Annuler ma demande',
                          icon: Icons.close,
                          onPressed: () async {
                            final success = await provider
                                .updateInterventionStatus(
                                  intervention.id,
                                  HomecareStatus.cancelled,
                                );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Votre demande a été annulée'),
                                ),
                              );
                              provider.loadIntervention(intervention.id);
                            }
                          },
                        ),
                      ],
                    ],

                    if (intervention.status == HomecareStatus.confirmed &&
                        isProfessional) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Démarrer l\'intervention',
                              icon: Icons.play_arrow,
                              onPressed: () async {
                                final success = await provider
                                    .updateInterventionStatus(
                                      intervention.id,
                                      HomecareStatus.inProgress,
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Intervention en cours'),
                                      backgroundColor: context.palette.warning,
                                    ),
                                  );
                                  provider.loadIntervention(intervention.id);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Annuler',
                              icon: Icons.close,
                              onPressed: () async {
                                final success = await provider
                                    .updateInterventionStatus(
                                      intervention.id,
                                      HomecareStatus.cancelled,
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Intervention annulée'),
                                    ),
                                  );
                                  provider.loadIntervention(intervention.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Audit Module 18 (HOM, 30/08/2026) : un second bouton
                    // « Terminer » existait ici, avec un `onPressed` vide
                    // (« Scroll to report section / Already handled above »)
                    // — code mort, strictement redondant avec le bouton
                    // fonctionnel « Terminer l'intervention » de la carte
                    // compte-rendu ci-dessus (rendue sous exactement la même
                    // condition `isProfessional && status == inProgress`).
                    // Supprimé plutôt que corrigé : aucune perte de
                    // fonctionnalité, la carte compte-rendu couvre déjà ce
                    // cas.
                    if (intervention.status.isPast &&
                        (isProfessional || isPatient)) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _confirmDelete(context, intervention.id),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.palette.danger,
                          side: BorderSide(color: context.palette.danger),
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
          SizedBox(width: 120, child: Text(label, style: context.text.label)),
          Expanded(child: Text(value, style: context.text.body1)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(HomecareStatus status) {
    switch (status) {
      case HomecareStatus.pending:
        return context.palette.warning;
      case HomecareStatus.confirmed:
        return context.palette.success;
      case HomecareStatus.inProgress:
        return context.palette.primary;
      case HomecareStatus.completed:
        return context.palette.secondary;
      case HomecareStatus.cancelled:
        return context.palette.danger;
      case HomecareStatus.missed:
        return context.palette.textSecondary;
    }
  }

  void _showRefusalDialog(
    BuildContext context,
    HomecareProvider provider,
    String interventionId,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Refuser la demande'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Motif du refus (obligatoire)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Le motif du refus est obligatoire'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              final success = await provider.updateInterventionStatus(
                interventionId,
                HomecareStatus.cancelled,
                refusalReason: reason,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Intervention refusée')),
                );
                provider.loadIntervention(interventionId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.onDanger,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Supprimer l\'intervention'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette intervention ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<HomecareProvider>()
                  .deleteIntervention(id);
              if (success && context.mounted) {
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.onDanger,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
