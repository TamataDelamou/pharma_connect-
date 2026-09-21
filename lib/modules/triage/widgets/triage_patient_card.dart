import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/triage_patient.dart';
import '../models/triage_status.dart';

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
              color: _priorityColor(patient.priorityLevel),
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
                        style: PharmaConnectTypography.body1.copyWith(
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
                          patient.priorityLevel,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'P${patient.priorityLevel}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _priorityColor(patient.priorityLevel),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  patient.chiefComplaint,
                  style: PharmaConnectTypography.body2,
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
                    Text(
                      patient.status.label,
                      style: PharmaConnectTypography.micro,
                    ),
                    const Spacer(),
                    Text(
                      'Arrivé à ${patient.arrivalTime.hour}:${patient.arrivalTime.minute.toString().padLeft(2, '0')}',
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

  Color _priorityColor(int level) {
    switch (level) {
      case 1:
        return PharmaConnectColors.accentRed;
      case 2:
        return PharmaConnectColors.accentOrange;
      case 3:
        return PharmaConnectColors.accentAmber;
      case 4:
        return PharmaConnectColors.accentCyan;
      case 5:
        return PharmaConnectColors.accentGreen;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }
}
