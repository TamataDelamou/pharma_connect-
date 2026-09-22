import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/insurance_enrollment.dart';

class EnrollmentCard extends StatelessWidget {
  final InsuranceEnrollment enrollment;
  final VoidCallback onTap;

  const EnrollmentCard({
    super.key,
    required this.enrollment,
    required this.onTap,
  });

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
              color: enrollment.isActive
                  ? PharmaConnectColors.accentGreen.withValues(alpha: 0.15)
                  : PharmaConnectColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.assignment_ind,
              color: enrollment.isActive
                  ? PharmaConnectColors.accentGreen
                  : PharmaConnectColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enrollment.planName ?? 'Plan',
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  enrollment.companyName ?? enrollment.companyId ?? '',
                  style: PharmaConnectTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (enrollment.isActive
                                    ? PharmaConnectColors.accentGreen
                                    : PharmaConnectColors.textSecondary)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        enrollment.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: enrollment.isActive
                              ? PharmaConnectColors.accentGreen
                              : PharmaConnectColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'N° ${enrollment.policyNumber}',
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
}
