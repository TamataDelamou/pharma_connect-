import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';
import '../providers/reservation_provider.dart';

class PharmacyQueueScreen extends StatefulWidget {
  const PharmacyQueueScreen({super.key});

  @override
  State<PharmacyQueueScreen> createState() => _PharmacyQueueScreenState();
}

class _PharmacyQueueScreenState extends State<PharmacyQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  // Bug corrigé (audit Module 6, 29/08/2026) : cet écran utilisait un
  // pharmacyId en dur ('ph_1') au lieu de AuthProvider.pharmacyId — la file
  // d'attente affichée n'était donc jamais celle de l'officine réellement
  // connectée. Même défaut que 'admin' (Module 4)/'patient_123' (Modules 5
  // et 6).
  Future<void> _refresh() async {
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) return;
    await context.read<ReservationProvider>().refreshQueue(pharmacyId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ReservationProvider>();
    // Aucun contrôle d'accès n'existait sur cet écran (audit Module 6) :
    // n'importe quel utilisateur authentifié pouvait consulter la file
    // d'attente d'une officine (identités de patients incluses) et déclencher
    // "Prêt"/"Retiré" — même patron de correction que prescription_detail_
    // screen.dart au Module 5.
    final isPharmacist = auth.effectiveRole == UserRole.pharmacien;
    final pharmacyId = auth.pharmacyId;

    if (!isPharmacist) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'Réservé aux pharmaciens de l\'officine.',
                  style: PharmaConnectTypography.body2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (pharmacyId == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Aucune officine rattachée à ce compte pharmacien.',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

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
            (a, b) => (a.queuePosition ?? 0).compareTo(b.queuePosition ?? 0),
          );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // C233 : en-tête adaptable (actions sous le titre sur téléphone).
              HeaderRow(
                leading: Row(
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: [
                  const KernelBadge(),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: PharmaConnectColors.textSecondary,
                    ),
                    onPressed: _refresh,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${queue.length} client(s) en attente de retrait',
                style: PharmaConnectTypography.body2,
              ),
              if (provider.isOffline && provider.reservations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PharmaConnectColors.accentAmber.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: PharmaConnectColors.accentAmber.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 16,
                        color: PharmaConnectColors.accentAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error ??
                              'Hors connexion — dernière file synchronisée.',
                          style: PharmaConnectTypography.micro.copyWith(
                            color: PharmaConnectColors.accentAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    // Bug corrigé (audit Module 6) : même garde
                    // `&& provider.reservations.isEmpty` qu'ailleurs, pour
                    // ne pas masquer la file en cache derrière une erreur
                    // bloquante en mode hors-ligne.
                    : provider.error != null && provider.reservations.isEmpty
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
                              onPressed: _refresh,
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
