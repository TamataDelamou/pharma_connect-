import 'package:flutter/material.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';
import '../../../core/theme/palette.dart';

class ReservationStatusCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onTap;

  const ReservationStatusCard({
    super.key,
    required this.reservation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: reservation.statusColor.of(context.palette),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${reservation.id}',
                      style: context.text.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${reservation.items.length} article(s)',
                      style: context.text.body2,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: reservation.statusColor
                      .of(context.palette)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: reservation.statusColor
                        .of(context.palette)
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      reservation.statusIcon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reservation.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: reservation.statusColor.of(context.palette),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${reservation.pharmacyName}', style: context.text.body2),
          if (reservation.queuePosition != null &&
              reservation.queuePosition! > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: context.palette.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(reservation.queueDisplay, style: context.text.micro),
                const SizedBox(width: 12),
                Icon(
                  Icons.timer,
                  size: 16,
                  color: context.palette.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  reservation.estimatedWaitDisplay,
                  style: context.text.micro,
                ),
              ],
            ),
          ],
          if (reservation.status == ReservationStatus.ready) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.palette.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.palette.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: context.palette.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Prêt à être retiré !',
                      style: context.text.body2.copyWith(
                        color: context.palette.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (reservation.isRunningOutOfTime) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.palette.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.palette.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: context.palette.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attention : délai de retrait bientôt dépassé',
                      style: context.text.body2.copyWith(
                        color: context.palette.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
