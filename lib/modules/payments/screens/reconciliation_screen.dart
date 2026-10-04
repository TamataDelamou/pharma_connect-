import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../models/transaction_status.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/palette.dart';

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen> {
  bool _isReconciling = false;

  // Bug corrigé (audit Module 8, 29/08/2026) : appel non filtré — pour un
  // pharmacien, RLS (transactions_select_own avant correctif) ne renvoyait
  // que ses propres transactions patient éventuelles, jamais celles de son
  // officine. Corrigé pour appeler avec pharmacyId dès que disponible ;
  // combiné à la nouvelle policy transactions_staff_select (migration
  // 20260829019000).
  Future<void> _refresh() async {
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) return;
    await context.read<PaymentProvider>().loadTransactions(
      pharmacyId: pharmacyId,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<PaymentProvider>();

    // Bug corrigé (audit Module 8, 29/08/2026) : aucun contrôle d'accès
    // n'existait sur ce back-office de réconciliation — n'importe quel
    // utilisateur authentifié pouvait l'ouvrir (cahier de conception :
    // "Back-office de réconciliation pharmacie"). Même patron de correction
    // que pharmacy_queue_screen.dart (Module 6) / delivery_schedule_screen.dart
    // (Module 7).
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

    final pendingTransactions = provider.transactions
        .where((t) => t.status == TransactionStatus.pending)
        .toList();

    final completedTransactions = provider.transactions
        .where(
          (t) =>
              t.status == TransactionStatus.completed ||
              t.status == TransactionStatus.processing,
        )
        .toList();

    final totalPending = pendingTransactions.fold(
      0,
      (sum, t) => sum + t.finalAmount,
    );
    final totalCompleted = completedTransactions.fold(
      0,
      (sum, t) => sum + t.finalAmount,
    );

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
                      'Réconciliation',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez et réconciliez vos transactions',
              style: context.text.body2,
            ),
            const SizedBox(height: 24),

            if (provider.isLoading) ...[
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ] else ...[
              // Résumé
              Row(
                children: [
                  _buildSummaryCard(
                    label: 'En attente',
                    value: pendingTransactions.length.toString(),
                    amount: totalPending,
                    color: context.palette.warning,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    label: 'À réconcilier',
                    value: completedTransactions.length.toString(),
                    amount: totalCompleted,
                    color: context.palette.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    label: 'Total',
                    value: provider.transactions.length.toString(),
                    amount: totalPending + totalCompleted,
                    color: context.palette.success,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Transactions en attente
              Text(
                'Transactions en attente de réconciliation',
                style: context.text.heading3,
              ),
              const SizedBox(height: 8),

              Expanded(
                child: pendingTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: context.palette.success,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Toutes les transactions sont réconciliées',
                              style: context.text.body2,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pendingTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = pendingTransactions[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.palette.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${transaction.id}',
                                        style: context.text.body1.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        transaction.pharmacyName ?? 'Pharmacie',
                                        style: context.text.body2,
                                      ),
                                      Text(
                                        '${CurrencyFormatter.format(transaction.finalAmount)} • ${_formatDate(transaction.createdAt)}',
                                        style: context.text.micro,
                                      ),
                                    ],
                                  ),
                                ),
                                PrimaryButton(
                                  label: 'Réconcilier',
                                  onPressed: _isReconciling
                                      ? null
                                      : () async {
                                          setState(() => _isReconciling = true);
                                          final success = await provider
                                              .confirmPayment(transaction.id);
                                          setState(
                                            () => _isReconciling = false,
                                          );
                                          if (success && context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Transaction réconciliée',
                                                ),
                                                backgroundColor:
                                                    PharmaConnectColors
                                                        .accentGreen,
                                              ),
                                            );
                                          }
                                        },
                                  width: 120,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required int amount,
    required Color color,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.text.micro),
            Text(
              value,
              style: context.text.kpiMedium.copyWith(
                color: color,
                fontSize: 20,
              ),
            ),
            Text(CurrencyFormatter.format(amount), style: context.text.micro),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
