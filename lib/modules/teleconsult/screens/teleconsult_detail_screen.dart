import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/teleconsult_provider.dart';
import '../models/consultation_status.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class TeleconsultDetailScreen extends StatefulWidget {
  final String consultationId;

  const TeleconsultDetailScreen({super.key, required this.consultationId});

  @override
  State<TeleconsultDetailScreen> createState() =>
      _TeleconsultDetailScreenState();
}

class _TeleconsultDetailScreenState extends State<TeleconsultDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeleconsultProvider>().loadConsultation(
        widget.consultationId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeleconsultProvider>();
    final consultation = provider.selectedConsultation;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (consultation == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Consultation introuvable',
            style: context.text.body2.copyWith(color: context.palette.danger),
          ),
        ),
      );
    }

    final isProfessional =
        consultation.professionalId == SupabaseService().currentUser?.id;
    final isPatient =
        consultation.patientId == SupabaseService().currentUser?.id;

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
                      'Détail de la consultation',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (consultation.status.isActive &&
                    consultation.meetingUrl != null &&
                    (isProfessional || isPatient))
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: open meeting URL (launch url)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ouverture du lien de visio (à implémenter)',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.video_call),
                    label: const Text('Rejoindre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.success,
                      foregroundColor: context.palette.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status banner
                    GlassCard(
                      glow: true,
                      glowColor:
                          consultation.status == ConsultationStatus.confirmed
                          ? context.palette.success
                          : consultation.status == ConsultationStatus.pending
                          ? context.palette.warning
                          : context.palette.textSecondary,
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _statusColor(consultation.status),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Statut : ${consultation.status.label}',
                                  style: context.text.heading3,
                                ),
                                Text(
                                  _formatDate(consultation.scheduledAt),
                                  style: context.text.body2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Details
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Patient',
                            consultation.patientName ?? consultation.patientId,
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          _buildDetailRow(
                            'Professionnel',
                            consultation.professionalName ??
                                consultation.professionalId,
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          _buildDetailRow(
                            'Durée',
                            '${consultation.durationMinutes} min',
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          if (consultation.reason != null)
                            _buildDetailRow('Motif', consultation.reason!),
                          if (consultation.meetingUrl != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildDetailRow(
                              'Lien de visio',
                              consultation.meetingUrl!,
                            ),
                          ],
                          if (consultation.professionalNotes != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildDetailRow(
                              'Notes du professionnel',
                              consultation.professionalNotes!,
                            ),
                          ],
                          if (consultation.patientFeedback != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildDetailRow(
                              'Feedback du patient',
                              consultation.patientFeedback!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    if (consultation.status == ConsultationStatus.pending) ...[
                      if (isProfessional) ...[
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'Confirmer',
                                icon: Icons.check_circle,
                                onPressed: () async {
                                  final success = await provider
                                      .updateConsultationStatus(
                                        consultation.id,
                                        ConsultationStatus.confirmed,
                                      );
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Consultation confirmée'),
                                        backgroundColor:
                                            context.palette.success,
                                      ),
                                    );
                                    provider.loadConsultation(consultation.id);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SecondaryButton(
                                label: 'Refuser',
                                icon: Icons.close,
                                onPressed: () async {
                                  final success = await provider
                                      .updateConsultationStatus(
                                        consultation.id,
                                        ConsultationStatus.cancelled,
                                      );
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Consultation annulée'),
                                      ),
                                    );
                                    provider.loadConsultation(consultation.id);
                                  }
                                },
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
                                .updateConsultationStatus(
                                  consultation.id,
                                  ConsultationStatus.cancelled,
                                );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Votre demande a été annulée'),
                                ),
                              );
                              provider.loadConsultation(consultation.id);
                            }
                          },
                        ),
                      ],
                    ],

                    if (consultation.status == ConsultationStatus.confirmed &&
                        isProfessional) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Marquer comme terminée',
                              icon: Icons.done_all,
                              onPressed: () async {
                                final success = await provider
                                    .updateConsultationStatus(
                                      consultation.id,
                                      ConsultationStatus.completed,
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Consultation terminée'),
                                      backgroundColor: context.palette.success,
                                    ),
                                  );
                                  provider.loadConsultation(consultation.id);
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
                                    .updateConsultationStatus(
                                      consultation.id,
                                      ConsultationStatus.cancelled,
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Consultation annulée'),
                                    ),
                                  );
                                  provider.loadConsultation(consultation.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (consultation.status == ConsultationStatus.confirmed &&
                        isPatient) ...[
                      SecondaryButton(
                        label: 'Annuler la consultation',
                        icon: Icons.close,
                        onPressed: () async {
                          final success = await provider
                              .updateConsultationStatus(
                                consultation.id,
                                ConsultationStatus.cancelled,
                              );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Consultation annulée'),
                              ),
                            );
                            provider.loadConsultation(consultation.id);
                          }
                        },
                      ),
                    ],

                    // Delete button (only for past consultations or for admin)
                    if (consultation.status.isPast &&
                        (isProfessional || isPatient)) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _confirmDelete(context, consultation.id),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  Color _statusColor(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.pending:
        return context.palette.warning;
      case ConsultationStatus.confirmed:
        return context.palette.success;
      case ConsultationStatus.completed:
        return context.palette.primary;
      case ConsultationStatus.cancelled:
        return context.palette.danger;
      case ConsultationStatus.missed:
        return context.palette.textSecondary;
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Supprimer la consultation'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette consultation ? Cette action est irréversible.',
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
                  .read<TeleconsultProvider>()
                  .deleteConsultation(id);
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
