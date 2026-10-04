import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/iot_device.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class DeviceCard extends StatelessWidget {
  final IotDevice device;
  final VoidCallback onTap;

  const DeviceCard({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_deviceIcon(device.type), style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            device.name,
            style: context.text.body1.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            device.typeLabel,
            style: context.text.micro,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(
                context,
                device.status,
              ).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              device.statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _statusColor(context, device.status),
              ),
            ),
          ),
          if (device.lastBatteryLevel != null) ...[
            const SizedBox(height: 4),
            Text(
              '🔋 ${device.lastBatteryLevel}%',
              style: TextStyle(
                fontSize: 10,
                color: device.lastBatteryLevel! < 20
                    ? context.palette.danger
                    : context.palette.textSecondary,
              ),
            ),
          ],
          if (device.lastReadingAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Dernière lecture: ${_formatDate(device.lastReadingAt!)}',
              style: TextStyle(fontSize: 9, color: context.palette.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  String _deviceIcon(String type) {
    switch (type) {
      case 'temperature_sensor':
        return '🌡️';
      case 'humidity_sensor':
        return '💧';
      case 'cold_chain_monitor':
        return '❄️';
      case 'stock_scanner':
        return '📷';
      case 'motion_sensor':
        return '🔄';
      default:
        return '📡';
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'active':
        return context.palette.success;
      case 'inactive':
        return context.palette.textSecondary;
      case 'maintenance':
        return context.palette.warning;
      case 'offline':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
    }
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
