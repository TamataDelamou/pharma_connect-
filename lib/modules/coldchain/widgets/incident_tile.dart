import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../models/cold_incident.dart';

class IncidentTile extends StatelessWidget {
  final ColdIncident incident;
  final VoidCallback? onResolve;

  const IncidentTile({super.key, required this.incident, this.onResolve});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: incident.severityColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: incident.severityColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                incident.severityLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: incident.severityColor,
                ),
              ),
              const SizedBox(width: 8),
              if (incident.isResolved) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: PharmaConnectColors.accentGreen.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Résolu',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: PharmaConnectColors.accentGreen,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: PharmaConnectColors.accentOrange.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'En cours',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: PharmaConnectColors.accentOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${incident.productName} (Lot: ${incident.batchNumber})',
            style: PharmaConnectTypography.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${incident.temperatureRecorded}°C - Plage: ${incident.minTemperature}°C à ${incident.maxTemperature}°C',
            style: PharmaConnectTypography.body2,
          ),
          Text(
            _formatDateTime(incident.occurredAt) +
                (incident.isResolved
                    ? ' • Résolu en ${incident.duration}'
                    : ''),
            style: PharmaConnectTypography.micro,
          ),
          if (!incident.isResolved && onResolve != null) ...[
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Marquer comme résolu',
              onPressed: onResolve,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
