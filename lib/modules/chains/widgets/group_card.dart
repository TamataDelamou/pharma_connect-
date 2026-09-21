import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/pharmacy_group.dart';

class GroupCard extends StatelessWidget {
  final PharmacyGroup group;
  final VoidCallback onTap;

  const GroupCard({super.key, required this.group, required this.onTap});

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
              color: group.isActive
                  ? PharmaConnectColors.accentCyan.withValues(alpha: 0.15)
                  : PharmaConnectColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                group.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: group.isActive
                      ? PharmaConnectColors.accentCyan
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
                Text(
                  group.name,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (group.code != null)
                  Text(
                    'Code: ${group.code}',
                    style: PharmaConnectTypography.micro,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${group.memberCount ?? 0} officines',
                      style: PharmaConnectTypography.micro.copyWith(
                        color: PharmaConnectColors.accentCyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: group.isActive
                            ? PharmaConnectColors.accentGreen.withValues(
                                alpha: 0.15,
                              )
                            : PharmaConnectColors.accentRed.withValues(
                                alpha: 0.15,
                              ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        group.isActive ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: group.isActive
                              ? PharmaConnectColors.accentGreen
                              : PharmaConnectColors.accentRed,
                        ),
                      ),
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
}
