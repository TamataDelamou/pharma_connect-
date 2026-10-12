import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/layout/responsive.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/reservation_provider.dart';
import '../widgets/pickup_qr_code.dart';
import '../widgets/queue_position_widget.dart';
import '../../../core/theme/palette.dart';

class ReservationConfirmationScreen extends StatelessWidget {
  const ReservationConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final reservation = provider.selectedReservation;

    if (reservation == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: context.palette.veil(0.24),
              ),
              const SizedBox(height: 16),
              Text('Aucune réservation à confirmer', style: context.text.body2),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                GlassCard(
                  glow: true,
                  glowColor: context.palette.success,
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: context.palette.success,
                        size: 64,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Commande confirmée !',
                        style: context.text.heading2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Votre réservation chez ${reservation.pharmacyName} a été prise en compte',
                        style: context.text.body2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.palette.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.palette.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Numéro de commande',
                              style: context.text.label,
                            ),
                            Text(
                              reservation.id,
                              style: context.text.kpiMedium.copyWith(
                                color: context.palette.primary,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                QueuePositionWidget(
                  position: reservation.queuePosition ?? 0,
                  estimatedMinutes: reservation.estimatedWaitMinutes ?? 0,
                  isReady: reservation.isReady,
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    children: [
                      Text('QR Code de retrait', style: context.text.heading3),
                      const SizedBox(height: 8),
                      PickupQrCode(
                        data:
                            reservation.qrCodeToken ??
                            'reservation_${reservation.id}',
                        extent: 192,
                      ),
                      const SizedBox(height: 8),
                      // C243 : code de retrait, exigé par l'officine.
                      Text(
                        reservation.qrCodeToken ?? '—',
                        style: context.text.heading3.copyWith(letterSpacing: 4),
                      ),
                      Text(
                        'Présentez ce QR code en pharmacie',
                        style: context.text.micro,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // C253 : l'un sous l'autre en largeur téléphone.
                ResponsiveActions(
                  children: [
                    OutlinedButton(
                      onPressed: () => context.push('/reservations/qr'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.palette.veil(0.24)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Voir mon QR code'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.go('/reservations/history'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.palette.primary,
                        foregroundColor: context.palette.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Voir l\'historique'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Retour à l\'accueil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
