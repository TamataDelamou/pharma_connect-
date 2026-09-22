import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import '../models/health_record.dart';

class AllergyTile extends StatelessWidget {
  final Allergy allergy;

  const AllergyTile({super.key, required this.allergy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: PharmaConnectColors.accentRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PharmaConnectColors.accentRed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber,
            color: PharmaConnectColors.accentRed,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(allergy.name, style: PharmaConnectTypography.body1),
          ),
          if (allergy.severity != null)
            Text(
              allergy.severity!,
              style: PharmaConnectTypography.micro.copyWith(
                color: PharmaConnectColors.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
