import 'package:flutter/material.dart';
import '../models/health_record.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class MedicationTile extends StatelessWidget {
  final Medication medication;

  const MedicationTile({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: context.palette.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.palette.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.medication, color: context.palette.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.name, style: context.text.body1),
                if (medication.dosage != null || medication.frequency != null)
                  Text(
                    '${medication.dosage ?? ''} ${medication.frequency ?? ''}'
                        .trim(),
                    style: context.text.micro,
                  ),
              ],
            ),
          ),
          if (medication.prescribedBy != null)
            Text('Dr ${medication.prescribedBy}', style: context.text.micro),
        ],
      ),
    );
  }
}
