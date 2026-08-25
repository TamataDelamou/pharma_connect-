import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/alert.dart';
import '../models/alert_type.dart';
import '../models/alert_severity.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const AlertCard({
    super.key,
    required this.alert,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = alert.severity == AlertSeverity.critical;

    final card = GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône de sévérité
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: alert.severityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                alert.severityIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: alert.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: alert.isRead
                              ? PharmaConnectColors.textSecondary
                              : PharmaConnectColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isCritical) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentRed.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: PharmaConnectColors.accentRed,
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
                      ),
                    ],
                    if (!alert.isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PharmaConnectColors.accentCyan,
                          boxShadow: [
                            BoxShadow(
                              color: PharmaConnectColors.accentCyan.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: PharmaConnectTypography.body2.copyWith(
                    color: isCritical ? PharmaConnectColors.textPrimary : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(alert.timeAgo, style: PharmaConnectTypography.micro),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: alert.severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.type.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: alert.severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              if (alert.actionLabel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: PharmaConnectColors.accentCyan.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alert.actionLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: PharmaConnectColors.accentCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: PharmaConnectColors.textSecondary,
                ),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );

    if (!isCritical) return card;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PharmaConnectColors.accentRed, width: 2),
      ),
      child: card,
    );
  }
}
