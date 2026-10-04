import 'package:flutter/material.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/alert.dart';
import '../models/alert_type.dart';
import '../models/alert_severity.dart';
import '../../../core/theme/palette.dart';

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
              color: alert.severityColor
                  .of(context.palette)
                  .withValues(alpha: 0.15),
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
                        style: context.text.body1.copyWith(
                          fontWeight: alert.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: alert.isRead
                              ? context.palette.textSecondary
                              : context.palette.textPrimary,
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
                          color: context.palette.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: context.palette.danger,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: context.palette.danger,
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
                          color: context.palette.primary,
                          boxShadow: [
                            BoxShadow(
                              color: context.palette.primary.withValues(
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
                  style: context.text.body2.copyWith(
                    color: isCritical ? context.palette.textPrimary : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(alert.timeAgo, style: context.text.micro),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: alert.severityColor
                            .of(context.palette)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.type.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: alert.severityColor.of(context.palette),
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
                    color: context.palette.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alert.actionLabel!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.palette.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: context.palette.textSecondary,
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
        border: Border.all(color: context.palette.danger, width: 2),
      ),
      child: card,
    );
  }
}
