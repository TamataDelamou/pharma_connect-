import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/ticket.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const TicketCard({super.key, required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: _priorityColor(context, ticket.priority),
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
                    Expanded(
                      child: Text(
                        ticket.subject,
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ticket.isSlaBreached) ...[
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: context.palette.danger,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          context,
                          ticket.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ticket.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(context, ticket.status),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(ticket.ticketNumber, style: context.text.mono),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      ticket.patientName ?? ticket.patientId,
                      style: context.text.body2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (ticket.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ticket.categoryName!,
                          style: context.text.micro,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(ticket.createdAt),
                      style: context.text.micro,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
        ],
      ),
    );
  }

  Color _priorityColor(BuildContext context, String priority) {
    switch (priority) {
      case 'critical':
        return context.palette.danger;
      case 'high':
        return context.palette.warning;
      case 'medium':
        return context.palette.primary;
      case 'low':
        return context.palette.textSecondary;
      default:
        return context.palette.textSecondary;
    }
  }

  Color _statusColor(BuildContext context, String status) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }
}
