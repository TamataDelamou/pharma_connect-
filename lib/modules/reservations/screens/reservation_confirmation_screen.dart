import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/reservation_provider.dart';
import '../widgets/queue_position_widget.dart';

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
              const Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.white24,
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune réservation à confirmer',
                style: PharmaConnectTypography.body2,
              ),
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
                  glowColor: PharmaConnectColors.accentGreen,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: PharmaConnectColors.accentGreen,
                        size: 64,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Commande confirmée !',
                        style: PharmaConnectTypography.heading2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Votre réservation chez ${reservation.pharmacyName} a été prise en compte',
                        style: PharmaConnectTypography.body2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentCyan.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PharmaConnectColors.accentCyan.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Numéro de commande',
                              style: PharmaConnectTypography.label,
                            ),
                            Text(
                              reservation.id,
                              style: PharmaConnectTypography.kpiMedium
                                  .copyWith(
                                    color: PharmaConnectColors.accentCyan,
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
                      const Text(
                        'QR Code de retrait',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data:
                              reservation.qrCodeToken ??
                              'reservation_${reservation.id}',
                          version: QrVersions.auto,
                          size: 160,
                          gapless: false,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Présentez ce QR code en pharmacie',
                        style: PharmaConnectTypography.micro,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/reservations/qr'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Voir mon QR code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            context.go('/reservations/history'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PharmaConnectColors.accentCyan,
                          foregroundColor: PharmaConnectColors.textOnAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Voir l\'historique'),
                      ),
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
