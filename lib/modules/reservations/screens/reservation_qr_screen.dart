import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/reservation_provider.dart';
import '../../../core/theme/palette.dart';

class ReservationQRScreen extends StatelessWidget {
  const ReservationQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final reservation = provider.selectedReservation;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: context.palette.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QR code de retrait',
                    style: context.text.heading2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: reservation == null
                  ? Center(
                      child: Text(
                        'Aucune réservation sélectionnée',
                        style: context.text.body2,
                      ),
                    )
                  : Center(
                      child: SingleChildScrollView(
                        child: GlassCard(
                          glow: true,
                          glowColor: context.palette.primary,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: context.palette.textPrimary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: QrImageView(
                                  data:
                                      reservation.qrCodeToken ??
                                      'reservation_${reservation.id}',
                                  version: QrVersions.auto,
                                  size: 220,
                                  gapless: false,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // C243 : code de retrait, à dicter si le QR
                              // ne peut pas être lu.
                              Text(
                                reservation.qrCodeToken ?? '—',
                                style: context.text.heading2.copyWith(
                                  letterSpacing: 4,
                                ),
                              ),
                              Text(
                                'Code de retrait',
                                style: context.text.micro,
                              ),
                              const SizedBox(height: 12),
                              const SizedBox(height: 4),
                              Text(
                                reservation.pharmacyName,
                                style: context.text.body2,
                              ),
                              Text(
                                reservation.pharmacyAddress,
                                style: context.text.micro,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: reservation.statusColor
                                      .of(context.palette)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: reservation.statusColor
                                        .of(context.palette)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '${reservation.statusIcon} ${reservation.statusLabel}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: reservation.statusColor.of(
                                      context.palette,
                                    ),
                                  ),
                                ),
                              ),
                              if (reservation.pickupDeadline != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'À retirer avant le '
                                  '${reservation.pickupDeadline!.day}/${reservation.pickupDeadline!.month} '
                                  'à ${reservation.pickupDeadline!.hour.toString().padLeft(2, '0')}h'
                                  '${reservation.pickupDeadline!.minute.toString().padLeft(2, '0')}',
                                  style: context.text.micro,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Text(
                                'Présentez ce QR code au comptoir de la pharmacie pour le retrait',
                                style: context.text.body2,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
