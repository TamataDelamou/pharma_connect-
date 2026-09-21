import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/solidarity_program.dart';

class ProgramCard extends StatelessWidget {
  final SolidarityProgram program;
  final VoidCallback onTap;

  const ProgramCard({super.key, required this.program, required this.onTap});

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
              color: _typeColor(program.type).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _typeIcon(program.type),
              color: _typeColor(program.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.name,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  program.typeLabel,
                  style: PharmaConnectTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (program.pharmacyName != null)
                      Text(
                        program.pharmacyName!,
                        style: PharmaConnectTypography.micro,
                      ),
                    const Spacer(),
                    if (program.beneficiariesCount != null)
                      Text(
                        '${program.beneficiariesCount} bénéficiaires',
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
                        color: program.isActive
                            ? PharmaConnectColors.accentGreen.withValues(
                                alpha: 0.15,
                              )
                            : PharmaConnectColors.accentRed.withValues(
                                alpha: 0.15,
                              ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        program.isActive ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: program.isActive
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

  IconData _typeIcon(String type) {
    switch (type) {
      case 'free_medication':
        return Icons.medication;
      case 'subsidized_care':
        return Icons.health_and_safety;
      case 'emergency_aid':
        return Icons.emergency;
      case 'health_education':
        return Icons.school;
      default:
        return Icons.handshake;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'free_medication':
        return PharmaConnectColors.accentGreen;
      case 'subsidized_care':
        return PharmaConnectColors.accentCyan;
      case 'emergency_aid':
        return PharmaConnectColors.accentRed;
      case 'health_education':
        return PharmaConnectColors.accentPurple;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }
}
