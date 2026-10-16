import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/text/whole_words_text.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';
import '../providers/reservation_provider.dart';
import '../widgets/reservation_status_card.dart';
import '../../../core/theme/palette.dart';

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

  void _showResult(bool ok, String success) {
    if (!mounted) return;
    final provider = context.read<ReservationProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? success : provider.error ?? 'Action impossible.'),
        backgroundColor: ok ? null : context.palette.danger,
      ),
    );
  }

  Future<void> _markReady(Reservation reservation) async {
    final ok = await context.read<ReservationProvider>().markAsReady(
      reservation.id,
    );
    _showResult(ok, 'Réservation prête.');
  }

  /// C243 : annulation par l'officine, motif obligatoire ; les boîtes
  /// retenues sont libérées par le serveur.
  Future<void> _cancel(Reservation reservation) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Annuler la réservation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Motif (obligatoire)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Garder'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Annuler la réservation'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    final ok = await context.read<ReservationProvider>().cancelReservation(
      reservation.id,
      reason: reason,
    );
    _showResult(ok, 'Réservation annulée, produits remis en vente.');
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
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: context.palette.veil(0.24),
                ),
                const SizedBox(height: 16),
                Text(
                  'Réservé aux pharmaciens de l\'officine.',
                  style: context.text.body2,
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
              style: context.text.body2,
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
                        "File d'attente pharmacie",
                        style: context.text.heading2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: [
                  const KernelBadge(),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: context.palette.textSecondary,
                    ),
                    onPressed: _refresh,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${queue.length} réservation(s) à retirer',
                style: context.text.body2,
              ),
              if (provider.isOffline && provider.reservations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.palette.warningStrong.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.palette.warningStrong.withValues(
                        alpha: 0.2,
                      ),
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
                              'Hors connexion — dernière file synchronisée.',
                          style: context.text.micro.copyWith(
                            color: context.palette.warningStrong,
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
                              provider.error!,
                              style: context.text.body2.copyWith(
                                color: context.palette.danger,
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: context.palette.veil(0.24),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Aucun client en file d'attente",
                              style: context.text.body2,
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
                              unavailableProducts: provider
                                  .unavailableProductsOf(reservation.id),
                              onMarkReady: () => _markReady(reservation),
                              // C243 : le retrait passe par l'écran de
                              // retrait, qui crée la vente au comptoir.
                              onPickup: () async {
                                await context.push(
                                  '/pharmacy/queue/pickup/${reservation.id}',
                                );
                                if (context.mounted) await _refresh();
                              },
                              onCancel: () => _cancel(reservation),
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
  final List<String> unavailableProducts;
  final VoidCallback onMarkReady;
  final VoidCallback onPickup;
  final VoidCallback onCancel;

  const _QueueEntryCard({
    required this.position,
    required this.reservation,
    required this.unavailableProducts,
    required this.onMarkReady,
    required this.onPickup,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = reservation.isOverdue;
    final statusColor = overdue
        ? context.palette.textSecondary
        : reservation.statusColor.of(context.palette);
    final deadline = reservation.pickupDeadline;
    final needsPrescription = reservation.items.any(
      (item) => item.prescriptionRequired && !item.isRemoved,
    );

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#$position',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: context.palette.onTint(statusColor),
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
                      style: context.text.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    WholeWordsText(
                      '${reservation.items.length} article(s) • '
                      '${CurrencyFormatter.format(reservation.totalPrice)} • '
                      '${overdue ? 'Expirée' : reservation.status.label}',
                      style: context.text.body2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (deadline != null) ...[
            const SizedBox(height: 8),
            Text(
              overdue
                  ? 'Délai de retrait dépassé depuis le '
                        '${formatReservationDateTime(deadline)}'
                  : 'À retirer avant le ${formatReservationDateTime(deadline)}',
              style: context.text.micro,
            ),
          ],
          if (needsPrescription) ...[
            const SizedBox(height: 4),
            Text(
              'Ordonnance à présenter au retrait',
              style: context.text.micro,
            ),
          ],
          if (unavailableProducts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.palette.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.palette.danger.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'Lot rappelé ou périmé : ${unavailableProducts.join(', ')}',
                style: context.text.body2.copyWith(
                  color: context.palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!overdue && !reservation.isReady)
                OutlinedButton(
                  onPressed: onMarkReady,
                  child: const Text('Prête'),
                ),
              if (!overdue)
                ElevatedButton(
                  onPressed: onPickup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
                  ),
                  child: const Text('Retrait'),
                ),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: context.palette.danger,
                ),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
