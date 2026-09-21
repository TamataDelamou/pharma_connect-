import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/ticket.dart';

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
              color: _priorityColor(ticket.priority),
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
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          ticket.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ticket.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(ticket.status),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(ticket.ticketNumber, style: PharmaConnectTypography.micro),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      ticket.patientName ?? ticket.patientId,
                      style: PharmaConnectTypography.body2,
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
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ticket.categoryName!,
                          style: PharmaConnectTypography.micro,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(ticket.createdAt),
                      style: PharmaConnectTypography.micro,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return PharmaConnectColors.accentRed;
      case 'high':
        return PharmaConnectColors.accentOrange;
      case 'medium':
        return PharmaConnectColors.accentCyan;
      case 'low':
        return PharmaConnectColors.textSecondary;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return PharmaConnectColors.accentOrange;
      case 'in_progress':
        return PharmaConnectColors.accentCyan;
      case 'waiting_for_patient':
        return PharmaConnectColors.accentPurple;
      case 'resolved':
        return PharmaConnectColors.accentGreen;
      case 'closed':
        return PharmaConnectColors.textSecondary;
      case 'cancelled':
        return PharmaConnectColors.accentRed;
      default:
        return PharmaConnectColors.textSecondary;
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
