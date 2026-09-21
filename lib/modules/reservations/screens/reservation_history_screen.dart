import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reservation.dart';
import '../providers/reservation_provider.dart';
import '../widgets/reservation_status_card.dart';

class ReservationHistoryScreen extends StatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  State<ReservationHistoryScreen> createState() =>
      _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  // Bug corrigé (audit Module 6, 29/08/2026) : 'patient_123' en dur, comme
  // dans reservation_checkout_screen.dart — reservations.patient_id est de
  // type uuid, cette liste ne pouvait jamais rien retourner en production
  // pour un vrai compte.
  void _load() {
    final patientId = context.read<AuthProvider>().userId;
    if (patientId == null) return;
    context.read<ReservationProvider>().loadPatientReservations(patientId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

    return Scaffold(
      body: Padding(
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
                    'Mes réservations',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'En cours'),
                Tab(text: 'Terminées'),
              ],
              labelColor: PharmaConnectColors.accentCyan,
              unselectedLabelColor: PharmaConnectColors.textSecondary,
              indicatorColor: PharmaConnectColors.accentCyan,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            if (provider.isOffline && provider.reservations.isNotEmpty) ...[
              // Bandeau informatif hors-ligne (directive standing) — même
              // patron que prescription_list_screen.dart (Module 5) : ne
              // jamais masquer les données en cache derrière une erreur.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
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
                            'Hors connexion — dernières données synchronisées.',
                        style: PharmaConnectTypography.micro.copyWith(
                          color: PharmaConnectColors.accentAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  // Bug corrigé (audit Module 6, 29/08/2026) : sans le
                  // `&& provider.reservations.isEmpty`, le message
                  // informatif hors-ligne (qui alimente aussi `error`)
                  // masquerait la liste mise en cache derrière un écran
                  // d'erreur bloquant — même bug déjà corrigé dans
                  // prescription_list_screen.dart (Module 5).
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
                            onPressed: _load,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(context, provider.activeReservations),
                        _buildList(context, provider.completedReservations),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Reservation> reservations) {
    if (reservations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Aucune réservation',
              style: PharmaConnectTypography.body2,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ReservationStatusCard(
            reservation: reservation,
            onTap: () async {
              await context.read<ReservationProvider>().loadReservation(
                reservation.id,
              );
              if (context.mounted) context.push('/reservations/qr');
            },
          ),
        );
      },
    );
  }
}
