import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/family_link.dart';
import '../models/family_link_status.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class FamilyLinkCard extends StatelessWidget {
  final FamilyLink link;
  final VoidCallback onTap;

  const FamilyLinkCard({super.key, required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: link.status.isActive
                  ? context.palette.success.withValues(alpha: 0.15)
                  : context.palette.textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (link.patientName ?? link.patientId)[0],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: link.status.isActive
                      ? context.palette.success
                      : context.palette.textSecondary,
                ),
              ),
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
                        link.patientName ?? link.patientId,
                        style: context.text.body1.copyWith(
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
                          context,
                          link.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        link.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(context, link.status),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  link.familyMemberName ?? link.familyMemberId,
                  style: context.text.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Relation : ${link.relationship}',
                  style: context.text.micro,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, FamilyLinkStatus status) {
    switch (status) {
      case FamilyLinkStatus.pending:
        return context.palette.warning;
      case FamilyLinkStatus.active:
        return context.palette.success;
      case FamilyLinkStatus.revoked:
        return context.palette.danger;
    }
  }
}
