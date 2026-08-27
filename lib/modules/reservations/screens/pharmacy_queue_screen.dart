import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';
import '../providers/reservation_provider.dart';

class PharmacyQueueScreen extends StatefulWidget {
  const PharmacyQueueScreen({super.key});

  @override
  State<PharmacyQueueScreen> createState() => _PharmacyQueueScreenState();
}

class _PharmacyQueueScreenState extends State<PharmacyQueueScreen> {
  // TODO: from auth — pharmacie de l'officine connectée
  static const String _pharmacyId = 'ph_1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().refreshQueue(_pharmacyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final queue =
        provider.reservations
            .where(
              (r) =>
                  r.status == ReservationStatus.pending ||
                  r.status == ReservationStatus.confirmed ||
                  r.status == ReservationStatus.ready,
            )
            .toList()
          ..sort(
            (a, b) =>
                (a.queuePosition ?? 0).compareTo(b.queuePosition ?? 0),
          );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<ReservationProvider>().refreshQueue(_pharmacyId),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: PharmaConnectColors.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "File d'attente pharmacie",
                      style: PharmaConnectTypography.heading2,
                    ),
                  ),
                  const KernelBadge(),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: PharmaConnectColors.textSecondary,
                    ),
                    onPressed: () => context
                        .read<ReservationProvider>()
                        .refreshQueue(_pharmacyId),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${queue.length} client(s) en attente de retrait',
                style: PharmaConnectTypography.body2,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Erreur : ${provider.error}',
                              style: PharmaConnectTypography.body2.copyWith(
                                color: PharmaConnectColors.accentRed,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<ReservationProvider>()
                                  .refreshQueue(_pharmacyId),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : queue.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.white24,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Aucun client en file d'attente",
                              style: PharmaConnectTypography.body2,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: queue.length,
                        itemBuilder: (context, index) {
                          final reservation = queue[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _QueueEntryCard(
                              position: index + 1,
                              reservation: reservation,
                              onMarkReady: () => context
                                  .read<ReservationProvider>()
                                  .markAsReady(reservation.id),
                              onMarkPickedUp: () => context
                                  .read<ReservationProvider>()
                                  .markAsPickedUp(reservation.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueEntryCard extends StatelessWidget {
  final int position;
  final Reservation reservation;
  final VoidCallback onMarkReady;
  final VoidCallback onMarkPickedUp;

  const _QueueEntryCard({
    required this.position,
    required this.reservation,
    required this.onMarkReady,
    required this.onMarkPickedUp,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: reservation.statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '#$position',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: reservation.statusColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.patientName,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${reservation.items.length} article(s) • ${reservation.statusLabel}',
                  style: PharmaConnectTypography.body2,
                ),
              ],
            ),
          ),
          if (reservation.status == ReservationStatus.confirmed)
            ElevatedButton(
              onPressed: onMarkReady,
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmaConnectColors.accentGreen,
                foregroundColor: PharmaConnectColors.textOnAccent,
              ),
              child: const Text('Prêt'),
            )
          else if (reservation.status == ReservationStatus.ready)
            ElevatedButton(
              onPressed: onMarkPickedUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmaConnectColors.accentCyan,
                foregroundColor: PharmaConnectColors.textOnAccent,
              ),
              child: const Text('Retiré'),
            ),
        ],
      ),
    );
  }
}
