import 'package:flutter/material.dart';
import '../../../core/theme/palette.dart';

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
          color: context.palette.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.palette.success.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: context.palette.success, size: 28),
            const SizedBox(width: 12),
            // C253 : texte souple, qui passe à la ligne à 360 px.
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commande prête !',
                    style: context.text.heading3.copyWith(
                      color: context.palette.success,
                    ),
                  ),
                  Text(
                    'Vous pouvez retirer votre commande',
                    style: context.text.body2,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.borderSubtle, width: 1),
      ),
      // C253 : deux moitiés égales ; les libellés passent à la ligne et les
      // grands chiffres rétrécissent s'ils ne tiennent pas. Côte à côte sans
      // élément souple, ils débordaient à 360 px.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Position dans la file',
                  style: context.text.label,
                  textAlign: TextAlign.center,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '#$position',
                    style: context.text.kpiLarge.copyWith(
                      color: context.palette.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Temps d\'attente estimé',
                  style: context.text.label,
                  textAlign: TextAlign.center,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    estimatedMinutes < 60
                        ? '$estimatedMinutes min'
                        : '${estimatedMinutes ~/ 60}h ${estimatedMinutes % 60}min',
                    style: context.text.kpiLarge.copyWith(
                      color: context.palette.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
