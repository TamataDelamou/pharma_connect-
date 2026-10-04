import 'package:flutter/material.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../models/cold_incident.dart';
import '../../../core/theme/palette.dart';

class IncidentTile extends StatelessWidget {
  final ColdIncident incident;
  final VoidCallback? onResolve;

  const IncidentTile({super.key, required this.incident, this.onResolve});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: incident.severityColor
            .of(context.palette)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: incident.severityColor
              .of(context.palette)
              .withValues(alpha: 0.2),
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
                  color: incident.severityColor.of(context.palette),
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
                    color: context.palette.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Résolu',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: context.palette.success,
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
                    color: context.palette.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'En cours',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: context.palette.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${incident.productName} (Lot: ${incident.batchNumber})',
            style: context.text.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            '${incident.temperatureRecorded}°C - Plage: ${incident.minTemperature}°C à ${incident.maxTemperature}°C',
            style: context.text.body2,
          ),
          Text(
            _formatDateTime(incident.occurredAt) +
                (incident.isResolved
                    ? ' • Résolu en ${incident.duration}'
                    : ''),
            style: context.text.micro,
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
