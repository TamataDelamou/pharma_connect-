import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class QueuePositionWidget extends StatelessWidget {
  final int position;
  final int estimatedMinutes;
  final bool isReady;

  const QueuePositionWidget({
    super.key,
    required this.position,
    required this.estimatedMinutes,
    this.isReady = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: PharmaConnectColors.accentGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: PharmaConnectColors.accentGreen.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: PharmaConnectColors.accentGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commande prête !',
                  style: PharmaConnectTypography.heading3.copyWith(
                    color: PharmaConnectColors.accentGreen,
                  ),
                ),
                Text(
                  'Vous pouvez retirer votre commande',
                  style: PharmaConnectTypography.body2,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              const Text(
                'Position dans la file',
                style: PharmaConnectTypography.label,
              ),
              Text(
                '#$position',
                style: PharmaConnectTypography.kpiLarge.copyWith(
                  color: PharmaConnectColors.accentCyan,
                ),
              ),
            ],
          ),
          const SizedBox(width: 40),
          Column(
            children: [
              const Text(
                'Temps d\'attente estimé',
                style: PharmaConnectTypography.label,
              ),
              Text(
                estimatedMinutes < 60
                    ? '$estimatedMinutes min'
                    : '${estimatedMinutes ~/ 60}h ${estimatedMinutes % 60}min',
                style: PharmaConnectTypography.kpiLarge.copyWith(
                  color: PharmaConnectColors.accentCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
