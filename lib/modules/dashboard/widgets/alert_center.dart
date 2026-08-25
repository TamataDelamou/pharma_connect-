import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/dashboard_data.dart';

class AlertCenter extends StatelessWidget {
  final List<AlertItem> alerts;

  const AlertCenter({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alertes', style: PharmaConnectTypography.heading3),
        const SizedBox(height: 16),
        ...alerts.map((alert) => _buildAlertItem(alert)),
      ],
    );
  }

  Widget _buildAlertItem(AlertItem alert) {
    final color = _getSeverityColor(alert.severity);
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
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return PharmaConnectColors.accentCyan;
      case AlertSeverity.warning:
        return PharmaConnectColors.accentOrange;
      case AlertSeverity.danger:
        return PharmaConnectColors.accentRed;
      case AlertSeverity.success:
        return PharmaConnectColors.accentGreen;
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
