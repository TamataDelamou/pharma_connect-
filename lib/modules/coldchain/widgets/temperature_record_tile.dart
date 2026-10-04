import 'package:flutter/material.dart';
import '../models/temperature_record.dart';
import '../../../core/theme/palette.dart';

class TemperatureRecordTile extends StatelessWidget {
  final TemperatureRecord record;

  const TemperatureRecordTile({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.palette.surfaceDisabled,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            record.isAlert ? Icons.error_outline : Icons.check_circle,
            color: record.statusColor.of(context.palette),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.temperature.toStringAsFixed(1)}°C',
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDateTime(record.timestamp),
                  style: context.text.micro,
                ),
              ],
            ),
          ),
          if (record.recordedBy != null) ...[
            Text(record.recordedBy!, style: context.text.micro),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: record.statusColor
                  .of(context.palette)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: record.statusColor.of(context.palette),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
