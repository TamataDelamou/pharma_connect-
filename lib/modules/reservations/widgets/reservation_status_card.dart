import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';

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
                  color: reservation.statusColor,
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
                      style: PharmaConnectTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${reservation.items.length} article(s)',
                      style: PharmaConnectTypography.body2,
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
                  color: reservation.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: reservation.statusColor.withValues(alpha: 0.3),
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
                        color: reservation.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${reservation.pharmacyName}',
            style: PharmaConnectTypography.body2,
          ),
          if (reservation.queuePosition != null &&
              reservation.queuePosition! > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  reservation.queueDisplay,
                  style: PharmaConnectTypography.micro,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  reservation.estimatedWaitDisplay,
                  style: PharmaConnectTypography.micro,
                ),
              ],
            ),
          ],
          if (reservation.status == ReservationStatus.ready) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PharmaConnectColors.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PharmaConnectColors.accentGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: PharmaConnectColors.accentGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Prêt à être retiré !',
                      style: PharmaConnectTypography.body2.copyWith(
                        color: PharmaConnectColors.accentGreen,
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
                color: PharmaConnectColors.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PharmaConnectColors.accentOrange.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: PharmaConnectColors.accentOrange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attention : délai de retrait bientôt dépassé',
                      style: PharmaConnectTypography.body2.copyWith(
                        color: PharmaConnectColors.accentOrange,
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
