import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/family_link.dart';
import '../models/family_link_status.dart';

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
                  ? PharmaConnectColors.accentGreen.withValues(alpha: 0.15)
                  : PharmaConnectColors.textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (link.patientName ?? link.patientId)[0],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: link.status.isActive
                      ? PharmaConnectColors.accentGreen
                      : PharmaConnectColors.textSecondary,
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
                          link.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        link.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(link.status),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  link.familyMemberName ?? link.familyMemberId,
                  style: PharmaConnectTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Relation : ${link.relationship}',
                  style: PharmaConnectTypography.micro,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Color _statusColor(FamilyLinkStatus status) {
    switch (status) {
      case FamilyLinkStatus.pending:
        return PharmaConnectColors.accentOrange;
      case FamilyLinkStatus.active:
        return PharmaConnectColors.accentGreen;
      case FamilyLinkStatus.revoked:
        return PharmaConnectColors.accentRed;
    }
  }
}
