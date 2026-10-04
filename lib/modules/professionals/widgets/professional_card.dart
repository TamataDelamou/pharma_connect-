import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../models/professional_profile.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class ProfessionalCard extends StatelessWidget {
  final ProfessionalProfile professional;
  final VoidCallback onTap;
  final bool showSelectButton;

  const ProfessionalCard({
    super.key,
    required this.professional,
    required this.onTap,
    this.showSelectButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: showSelectButton ? null : onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: professional.isVerified
                ? context.palette.success.withValues(alpha: 0.15)
                : context.palette.textSecondary.withValues(alpha: 0.1),
            child: Text(
              professional.fullName?.substring(0, 1) ?? 'P',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: professional.isVerified
                    ? context.palette.success
                    : context.palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        professional.fullName ?? professional.id,
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (professional.isVerified)
                      Icon(
                        Icons.verified,
                        color: context.palette.success,
                        size: 16,
                      ),
                  ],
                ),
                Text(
                  professional.specialty,
                  style: context.text.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (professional.isAcceptingNewPatients) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.success.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Disponible',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: context.palette.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (professional.consultationFee != null)
                      Text(
                        '${professional.consultationFee} GNF consultation',
                        style: context.text.micro,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (showSelectButton) ...[
            PrimaryButton(label: 'Choisir', onPressed: onTap, width: 100),
          ] else ...[
            Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
          ],
        ],
      ),
    );
  }
}
