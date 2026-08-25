import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/prescription.dart';

class PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onTap;
  final bool compact;

  const PrescriptionCard({
    super.key,
    required this.prescription,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icône de statut
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: prescription.statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusSm,
              ),
            ),
            child: Center(
              child: Text(
                prescription.statusLabel[0],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: prescription.statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prescription.patientName,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!compact) ...[
                  Text(
                    prescription.items
                        .map((item) => item.medicationName)
                        .join(', '),
                    style: PharmaConnectTypography.body2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: prescription.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        prescription.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: prescription.statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(prescription.uploadedAt),
                      style: PharmaConnectTypography.micro,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Indicateur de confiance OCR
          if (prescription.ocrConfidenceScore != null) ...[
            Column(
              children: [
                Text(
                  '${(prescription.ocrConfidenceScore! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: prescription.ocrConfidenceScore! > 0.8
                        ? PharmaConnectColors.accentGreen
                        : PharmaConnectColors.accentOrange,
                  ),
                ),
                const Text('Confiance', style: PharmaConnectTypography.micro),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }
}
