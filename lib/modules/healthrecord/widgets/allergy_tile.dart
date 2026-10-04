import 'package:flutter/material.dart';
import '../models/health_record.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class AllergyTile extends StatelessWidget {
  final Allergy allergy;

  const AllergyTile({super.key, required this.allergy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: context.palette.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.palette.danger.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: context.palette.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(allergy.name, style: context.text.body1)),
          if (allergy.severity != null)
            Text(
              allergy.severity!,
              style: context.text.micro.copyWith(
                color: context.palette.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
