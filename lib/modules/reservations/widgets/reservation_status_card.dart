import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/text/whole_words_text.dart';
import '../../../core/pilot/pilot_config.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';
import '../../../core/theme/palette.dart';

/// Date et heure d'échéance ou d'événement, au format « 05/10 à 14:30 ».
String formatReservationDateTime(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)} à ${two(d.hour)}:${two(d.minute)}';
}

class ReservationStatusCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onTap;

  /// C243 : produits de cette réservation qui ne sont plus disponibles (lot
  /// rappelé ou périmé depuis la réservation).
  final List<String> unavailableProducts;

  /// C243 : annulation par le patient ; bouton affiché tant que la
  /// réservation est active.
  final VoidCallback? onCancel;

  const ReservationStatusCard({
    super.key,
    required this.reservation,
    this.onTap,
    this.unavailableProducts = const [],
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // C243 : passé l'échéance, une réservation encore active est affichée
    // « expirée » sans attendre le passage de la tâche planifiée.
    final overdue = reservation.isActive && reservation.isOverdue;
    final active = reservation.isActive && !overdue;
    final statusColor = overdue
        ? context.palette.textSecondary
        : reservation.statusColor.of(context.palette);
    final needsPrescription = reservation.items.any(
      (item) => item.prescriptionRequired && !item.isRemoved,
    );

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
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.pharmacyName,
                      style: context.text.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    WholeWordsText(
                      '${reservation.items.length} article(s) • '
                      '${CurrencyFormatter.format(reservation.totalPrice)}',
                      style: context.text.body2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  overdue
                      ? ReservationStatus.expired.label
                      : reservation.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.onTint(statusColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_detail(overdue), style: context.text.body2),
          if (active && PilotConfig.payAtPickupLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${PilotConfig.payAtPickupLabel}. Prix indicatif : le prix du '
              'jour s\'applique au retrait.',
              style: context.text.micro,
            ),
          ],
          if (active && needsPrescription) ...[
            const SizedBox(height: 8),
            _notice(
              context,
              Icons.description_outlined,
              'Ordonnance à présenter au retrait',
              context.palette.primary,
            ),
          ],
          if (active && unavailableProducts.isNotEmpty) ...[
            const SizedBox(height: 8),
            _notice(
              context,
              Icons.error_outline,
              'Un produit de votre réservation n\'est plus disponible '
              '(${unavailableProducts.join(', ')}). Contactez l\'officine.',
              context.palette.danger,
            ),
          ],
          if (active && reservation.isRunningOutOfTime) ...[
            const SizedBox(height: 8),
            _notice(
              context,
              Icons.warning_amber,
              'Attention : délai de retrait bientôt dépassé',
              context.palette.warning,
            ),
          ],
          if (active && onCancel != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: context.palette.danger,
                ),
                child: const Text('Annuler la réservation'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _detail(bool overdue) {
    if (overdue || reservation.isExpired) {
      return 'Expirée : non retirée dans les 24 h';
    }
    switch (reservation.status) {
      case ReservationStatus.pending:
      case ReservationStatus.confirmed:
        return reservation.pickupDeadline == null
            ? 'Réservée'
            : 'Réservée — à retirer avant le '
                  '${formatReservationDateTime(reservation.pickupDeadline!)}';
      case ReservationStatus.ready:
        return reservation.pickupDeadline == null
            ? 'Prête'
            : 'Prête — à retirer avant le '
                  '${formatReservationDateTime(reservation.pickupDeadline!)}';
      case ReservationStatus.pickedUp:
        return reservation.pickedUpAt == null
            ? 'Retirée'
            : 'Retirée le ${formatReservationDateTime(reservation.pickedUpAt!)}';
      case ReservationStatus.cancelled:
        final by = reservation.cancelledBy == null
            ? 'Annulée'
            : reservation.cancelledBy == reservation.patientId
            ? 'Annulée par vous'
            : 'Annulée par l\'officine';
        final reason = reservation.cancelReason;
        return reason == null || reason.isEmpty ? by : '$by : $reason';
      case ReservationStatus.expired:
        return 'Expirée : non retirée dans les 24 h';
    }
  }

  Widget _notice(
    BuildContext context,
    IconData icon,
    String message,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.text.body2.copyWith(
                color: context.palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
