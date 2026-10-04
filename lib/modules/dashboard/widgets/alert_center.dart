import 'package:flutter/material.dart';
import '../../../core/theme/spacing.dart';
import '../models/dashboard_data.dart';
import '../../../core/theme/palette.dart';

class AlertCenter extends StatelessWidget {
  final List<AlertItem> alerts;

  const AlertCenter({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertes', style: context.text.heading3),
        const SizedBox(height: 16),
        ...alerts.map((alert) => _buildAlertItem(context, alert)),
      ],
    );
  }

  Widget _buildAlertItem(BuildContext context, AlertItem alert) {
    final color = _getSeverityColor(context.palette, alert.severity);
    final icon = _getSeverityIcon(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message,
              style: context.text.body2.copyWith(
                color: context.palette.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(PharmaConnectPalette p, AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return p.info;
      case AlertSeverity.warning:
        return p.warning;
      case AlertSeverity.danger:
        return p.danger;
      case AlertSeverity.success:
        return p.success;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber;
      case AlertSeverity.danger:
        return Icons.error_outline;
      case AlertSeverity.success:
        return Icons.check_circle_outline;
    }
  }
}
