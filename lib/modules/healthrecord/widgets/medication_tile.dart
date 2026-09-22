import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import '../models/health_record.dart';

class MedicationTile extends StatelessWidget {
  final Medication medication;

  const MedicationTile({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: PharmaConnectColors.accentGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PharmaConnectColors.accentGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.medication,
            color: PharmaConnectColors.accentGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.name, style: PharmaConnectTypography.body1),
                if (medication.dosage != null || medication.frequency != null)
                  Text(
                    '${medication.dosage ?? ''} ${medication.frequency ?? ''}'
                        .trim(),
                    style: PharmaConnectTypography.micro,
                  ),
              ],
            ),
          ),
          if (medication.prescribedBy != null)
            Text(
              'Dr ${medication.prescribedBy}',
              style: PharmaConnectTypography.micro,
            ),
        ],
      ),
    );
  }
}
