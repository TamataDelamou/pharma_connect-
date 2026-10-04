import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/support_provider.dart';
import '../models/ticket_response.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _replyController = TextEditingController();
  final _feedbackCommentController = TextEditingController();
  int _feedbackRating = 0;
  bool _isInternalReply = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().loadTicket(widget.ticketId);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _feedbackCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupportProvider>();
    final ticket = provider.selectedTicket;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (ticket == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Ticket introuvable',
            style: context.text.body2.copyWith(color: context.palette.danger),
          ),
        ),
      );
    }

    final isPatient = ticket.patientId == SupabaseService().currentUser?.id;
    final isStaff = context.watch<AuthProvider>().isGsgAdmin;

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
                  child: Text(
                    'Ticket #${ticket.ticketNumber}',
                    style: context.text.heading2,
                  ),
                ),
                const KernelBadge(),
                if (!ticket.isClosed) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        ticket.status,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _statusColor(
                          ticket.status,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      ticket.statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(ticket.status),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket info
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Sujet', ticket.subject),
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow('Priorité', ticket.priorityLabel),
                          Divider(color: context.palette.veil(0.12)),
                          if (ticket.categoryName != null) ...[
                            _buildInfoRow('Catégorie', ticket.categoryName!),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          _buildInfoRow(
                            'Patient',
                            ticket.patientName ?? ticket.patientId,
                          ),
                          if (ticket.assigneeName != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow('Assigné à', ticket.assigneeName!),
                          ],
                          if (ticket.createdAt != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Créé le',
                              _formatDate(ticket.createdAt),
                            ),
                          ],
                          if (ticket.resolvedAt != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Résolu le',
                              _formatDate(ticket.resolvedAt!),
                            ),
                          ],
                          if (ticket.slaDueAt != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      'Échéance SLA',
                                      style: context.text.label,
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          _formatDate(ticket.slaDueAt!),
                                          style: context.text.body1.copyWith(
                                            color: ticket.isSlaBreached
                                                ? context.palette.danger
                                                : null,
                                          ),
                                        ),
                                        if (ticket.isSlaBreached) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 16,
                                            color: context.palette.danger,
                                          ),
                                          Text(
                                            ' En retard',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: context.palette.danger,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow(
                            'Description',
                            ticket.description,
                            multiline: true,
                          ),
                        ],
                      ),
                    ),

                    if (ticket.isDispute) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.gavel,
                                  size: 18,
                                  color: context.palette.warning,
                                ),
                                const SizedBox(width: 8),
                                Text('Litige', style: context.text.heading3),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (ticket.disputeCategory != null)
                              _buildInfoRow(
                                'Type',
                                _disputeCategoryLabel(ticket.disputeCategory!),
                              ),
                            if (ticket.disputedAmount != null) ...[
                              Divider(color: context.palette.veil(0.12)),
                              _buildInfoRow(
                                'Montant contesté',
                                '${ticket.disputedAmount}',
                              ),
                            ],
                            if (ticket.disputeReferenceId != null) ...[
                              Divider(color: context.palette.veil(0.12)),
                              _buildInfoRow(
                                'Référence liée',
                                ticket.disputeReferenceId!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Responses
                    if (provider.responses.isNotEmpty) ...[
                      Text('Conversation', style: context.text.heading3),
                      const SizedBox(height: 8),
                      ...provider.responses.map((response) {
                        final isStaff = response.authorId != ticket.patientId;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isStaff
                                ? context.palette.primary.withValues(
                                    alpha: 0.06,
                                  )
                                : context.palette.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isStaff
                                  ? context.palette.primary.withValues(
                                      alpha: 0.2,
                                    )
                                  : context.palette.surface,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    response.authorName ?? response.authorId,
                                    style: context.text.body1.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDate(response.createdAt),
                                    style: context.text.micro,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(response.message, style: context.text.body2),
                              if (response.isInternal) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.palette.warning.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Interne',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: context.palette.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],

                    // Reply box
                    if (!ticket.isClosed) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Répondre', style: context.text.heading3),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _replyController,
                              decoration: const InputDecoration(
                                hintText: 'Votre message...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (isStaff) ...[
                                  Checkbox(
                                    value: _isInternalReply,
                                    onChanged: (v) => setState(
                                      () => _isInternalReply = v ?? false,
                                    ),
                                  ),
                                  const Text('Interne'),
                                  const SizedBox(width: 16),
                                ],
                                const Spacer(),
                                PrimaryButton(
                                  label: 'Envoyer',
                                  onPressed: () async {
                                    final message = _replyController.text
                                        .trim();
                                    if (message.isEmpty) return;
                                    final response = TicketResponse(
                                      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                                      ticketId: ticket.id,
                                      authorId:
                                          SupabaseService().currentUser!.id,
                                      message: message,
                                      isInternal: isStaff && _isInternalReply,
                                      attachments: const [],
                                      createdAt: DateTime.now().toUtc(),
                                      updatedAt: DateTime.now().toUtc(),
                                    );
                                    final success = await provider.addResponse(
                                      response,
                                    );
                                    if (success && context.mounted) {
                                      _replyController.clear();
                                      setState(() => _isInternalReply = false);
                                      provider.loadTicket(ticket.id);
                                    }
                                  },
                                  width: 120,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Feedback section (for patients when ticket is resolved)
                    if (isPatient &&
                        ticket.status == 'resolved' &&
                        !(ticket.hasFeedback ?? false)) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Évaluez votre expérience',
                              style: context.text.heading3,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (index) {
                                return IconButton(
                                  icon: Icon(
                                    index < _feedbackRating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: context.palette.warningStrong,
                                  ),
                                  onPressed: () => setState(
                                    () => _feedbackRating = index + 1,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _feedbackCommentController,
                              decoration: const InputDecoration(
                                hintText: 'Commentaire (optionnel)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 8),
                            PrimaryButton(
                              label: 'Envoyer le feedback',
                              onPressed: () async {
                                if (_feedbackRating == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Veuillez attribuer une note',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final success = await provider.submitFeedback(
                                  ticketId: ticket.id,
                                  patientId: SupabaseService().currentUser!.id,
                                  rating: _feedbackRating,
                                  comment: _feedbackCommentController.text
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
                                  provider.loadTicket(ticket.id);
                                }
                              },
                              width: 200,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Staff actions
                    if (isStaff && !ticket.isClosed) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (ticket.status == 'new') ...[
                            Expanded(
                              child: PrimaryButton(
                                label: 'Prendre en charge',
                                icon: Icons.assignment_turned_in,
                                onPressed: () async {
                                  final updated = ticket.copyWith(
                                    assignedTo:
                                        SupabaseService().currentUser?.id,
                                    status: 'in_progress',
                                  );
                                  final success = await provider.updateTicket(
                                    updated,
                                  );
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ticket pris en charge'),
                                      ),
                                    );
                                    provider.loadTicket(ticket.id);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: SecondaryButton(
                              label: ticket.status == 'new'
                                  ? 'Annuler'
                                  : 'Résoudre',
                              onPressed: () async {
                                final newStatus = ticket.status == 'new'
                                    ? 'cancelled'
                                    : 'resolved';
                                final success = await provider
                                    .updateTicketStatus(ticket.id, newStatus);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        newStatus == 'resolved'
                                            ? 'Ticket résolu'
                                            : 'Ticket annulé',
                                      ),
                                    ),
                                  );
                                  provider.loadTicket(ticket.id);
                                }
                              },
                            ),
                          ),
                          if (ticket.status != 'cancelled') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: SecondaryButton(
                                label: 'Fermer',
                                onPressed: () async {
                                  final success = await provider
                                      .updateTicketStatus(ticket.id, 'closed');
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ticket fermé'),
                                      ),
                                    );
                                    provider.loadTicket(ticket.id);
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Patient cancel action
                    if (isPatient && ticket.isOpen) ...[
                      const SizedBox(height: 16),
                      SecondaryButton(
                        label: 'Annuler ma demande',
                        icon: Icons.close,
                        onPressed: () async {
                          final success = await provider.updateTicketStatus(
                            ticket.id,
                            'cancelled',
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Demande annulée')),
                            );
                            provider.loadTicket(ticket.id);
                          }
                        },
                      ),
                    ],

                    // Delete (for staff)
                    if (isStaff && ticket.isClosed) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, ticket.id),
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

  Widget _buildInfoRow(String label, String value, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: context.text.label)),
          Expanded(
            child: Text(
              value,
              style: context.text.body1,
              maxLines: multiline ? null : 1,
              overflow: multiline
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _disputeCategoryLabel(String category) {
    switch (category) {
      case 'order':
        return 'Commande';
      case 'payment':
        return 'Paiement';
      case 'delivery':
        return 'Livraison';
      default:
        return category;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return context.palette.warning;
      case 'in_progress':
        return context.palette.primary;
      case 'waiting_for_patient':
        return context.palette.secondary;
      case 'resolved':
        return context.palette.success;
      case 'closed':
        return context.palette.textSecondary;
      case 'cancelled':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Supprimer'),
        content: const Text('Supprimer ce ticket de support ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<SupportProvider>()
                  .deleteTicket(id);
              if (success && context.mounted) context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.textPrimary,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
