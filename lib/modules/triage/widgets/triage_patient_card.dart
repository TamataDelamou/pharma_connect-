import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/triage_patient.dart';
import '../models/triage_status.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class TriagePatientCard extends StatelessWidget {
  final TriagePatient patient;
  final VoidCallback onTap;

  const TriagePatientCard({
    super.key,
    required this.patient,
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
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: _priorityColor(context, patient.priorityLevel),
              borderRadius: BorderRadius.circular(2),
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
                        patient.patientName ?? patient.patientId,
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _priorityColor(
                          context,
                          patient.priorityLevel,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'P${patient.priorityLevel}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _priorityColor(context, patient.priorityLevel),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  patient.chiefComplaint,
                  style: context.text.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      patient.status.icon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(patient.status.label, style: context.text.micro),
                    const Spacer(),
                    Text(
                      'Arrivé à ${patient.arrivalTime.hour}:${patient.arrivalTime.minute.toString().padLeft(2, '0')}',
                      style: context.text.micro,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
        ],
      ),
    );
  }

  Color _priorityColor(BuildContext context, int level) {
    switch (level) {
      case 1:
        return context.palette.danger;
      case 2:
        return context.palette.warning;
      case 3:
        return context.palette.warningStrong;
      case 4:
        return context.palette.primary;
      case 5:
        return context.palette.success;
      default:
        return context.palette.textSecondary;
    }
  }
}
