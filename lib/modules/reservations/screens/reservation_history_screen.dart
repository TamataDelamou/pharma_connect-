import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reservation.dart';
import '../providers/reservation_provider.dart';
import '../widgets/reservation_status_card.dart';
import '../../../core/theme/palette.dart';

class ReservationHistoryScreen extends StatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  State<ReservationHistoryScreen> createState() =>
      _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// C255 : réservation dont le QR code est en cours d'ouverture.
  String? _openingId;

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
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
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
                      'Mes réservations',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'En cours'),
                Tab(text: 'Terminées'),
              ],
              labelColor: context.palette.primary,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: context.palette.primary,
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
                  color: context.palette.warningStrong.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.palette.warningStrong.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: context.palette.warningStrong,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error ??
                            'Hors connexion — dernières données synchronisées.',
                        style: context.text.micro.copyWith(
                          color: context.palette.warningStrong,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // C255 : barre de progression pendant l'ouverture d'un QR code,
            // dans l'espace au-dessus de la liste (rien ne bouge à l'écran).
            SizedBox(
              height: 16,
              child: _openingId == null
                  ? null
                  : const Center(child: LinearProgressIndicator(minHeight: 3)),
            ),
            Expanded(
              // C255 : la roue ne remplace la liste que s'il n'y a encore
              // rien à montrer ; une liste déjà chargée reste affichée
              // pendant l'ouverture d'une réservation ou un rafraîchissement.
              child: provider.isLoading && provider.reservations.isEmpty
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
                            style: context.text.body2.copyWith(
                              color: context.palette.danger,
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

  /// C243 : annulation par le patient ; les boîtes retenues sont libérées
  /// par le serveur.
  Future<void> _confirmCancel(
    BuildContext context,
    Reservation reservation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Annuler la réservation ?'),
        content: const Text(
          'Les produits réservés seront remis en vente. Cette action est '
          'définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Garder'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Annuler la réservation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<ReservationProvider>();
    final ok = await provider.cancelReservation(reservation.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Réservation annulée.'
              : provider.error ?? 'Annulation impossible.',
        ),
        backgroundColor: ok ? null : context.palette.danger,
      ),
    );
  }

  /// C255 : ouvre le QR code d'une réservation. La navigation part de
  /// l'écran, pas de la carte touchée : la carte peut être retirée de l'écran
  /// pendant le chargement, et son contexte ne permet alors plus de naviguer.
  Future<void> _openQr(Reservation reservation) async {
    // Un toucher à la fois : le second est ignoré tant que le premier
    // n'est pas terminé.
    if (_openingId != null) return;
    setState(() => _openingId = reservation.id);
    final provider = context.read<ReservationProvider>();
    try {
      await provider.loadReservation(reservation.id);
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
    if (!mounted) return;
    // Chargement échoué : la réservation sélectionnée est restée celle
    // d'avant. Ne jamais montrer le QR code d'une autre réservation.
    if (provider.selectedReservation?.id != reservation.id) {
      // Hors connexion : la réservation de la liste, en cache, porte le code
      // de retrait. Le serveur le vérifie au retrait.
      if ((reservation.qrCodeToken ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Impossible d\'ouvrir cette réservation. Vérifiez la connexion '
              'et réessayez.',
            ),
            backgroundColor: context.palette.danger,
          ),
        );
        return;
      }
      provider.selectCachedReservation(reservation);
    }
    context.push('/reservations/qr');
  }

  Widget _buildList(BuildContext context, List<Reservation> reservations) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucune réservation', style: context.text.body2),
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
            // C243 : produit devenu indisponible, annulation par le patient.
            unavailableProducts: context
                .read<ReservationProvider>()
                .unavailableProductsOf(reservation.id),
            onCancel: () => _confirmCancel(context, reservation),
            onTap: () => _openQr(reservation),
          ),
        );
      },
    );
  }
}
