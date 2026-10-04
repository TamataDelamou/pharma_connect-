import 'package:flutter/material.dart';
import '../models/health_record.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class VaccinationTile extends StatelessWidget {
  final Vaccination vaccination;

  const VaccinationTile({super.key, required this.vaccination});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: context.palette.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.palette.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.vaccines, color: context.palette.secondary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(vaccination.name, style: context.text.body1)),
          if (vaccination.date != null)
            Text(
              '${vaccination.date!.day}/${vaccination.date!.month}/${vaccination.date!.year}',
              style: context.text.micro,
            ),
        ],
      ),
    );
  }
}
