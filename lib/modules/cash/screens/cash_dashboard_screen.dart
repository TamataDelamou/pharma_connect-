import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/cash_provider.dart';
import '../models/cash_movement.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class CashDashboardScreen extends StatefulWidget {
  const CashDashboardScreen({super.key});

  @override
  State<CashDashboardScreen> createState() => _CashDashboardScreenState();
}

class _CashDashboardScreenState extends State<CashDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      final pharmacyId = context.read<AuthProvider>().pharmacyId;
      if (pharmacyId == null) return;
      if (userId != null) {
        context.read<CashProvider>().loadCurrentSession(pharmacyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyId = context.watch<AuthProvider>().pharmacyId;
    if (pharmacyId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Aucune officine rattachée à ce compte pharmacien.',
            style: context.text.body2,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final provider = context.watch<CashProvider>();

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
                      '💰 Caisse',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (provider.hasOpenSession)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '🟢 Ouverte',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.palette.onTint(context.palette.success),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '🔴 Fermée',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.palette.onTint(context.palette.danger),
                      ),
                    ),
                  ),
              ],
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
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.palette.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style: context.text.body2.copyWith(
                              color: context.palette.danger,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: () {
                              provider.clearError();
                              final userId = SupabaseService().currentUser?.id;
                              final pharmacyId = context
                                  .read<AuthProvider>()
                                  .pharmacyId;
                              if (pharmacyId == null) return;
                              if (userId != null) {
                                provider.loadCurrentSession(pharmacyId);
                              }
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : provider.hasOpenSession
                  ? _buildOpenSession(provider)
                  : _buildNoSession(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenSession(CashProvider provider) {
    final session = provider.currentSession!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session info
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Session ouverte le',
                  _formatDate(session.openedAt),
                ),
                _buildInfoRow(
                  'Caissier',
                  session.cashierName ?? session.cashierId,
                ),
                _buildInfoRow(
                  'Fonds de caisse',
                  CurrencyFormatter.format(session.openingBalance),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary. C258 : toujours affiché pour une session ouverte ; un
          // montant inconnu (résumé non chargé) s'affiche « — ».
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Résumé', style: context.text.heading3),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Ventes',
                  provider.summary?['total_sales'] as int?,
                ),
                _buildSummaryRow(
                  'Remboursements',
                  provider.summary?['total_refunds'] as int?,
                ),
                _buildSummaryRow(
                  'Dépôts',
                  provider.summary?['total_deposits'] as int?,
                ),
                _buildSummaryRow(
                  'Retraits',
                  provider.summary?['total_withdrawals'] as int?,
                ),
                Divider(color: context.palette.veil(0.12)),
                _buildSummaryRow(
                  'Solde attendu',
                  provider.currentExpectedCash,
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Movements
          if (provider.movements.isNotEmpty) ...[
            Text('Mouvements récents', style: context.text.heading3),
            const SizedBox(height: 8),
            ...provider.movements.take(5).map((movement) {
              return Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: movement.isIncome
                      ? context.palette.success.withValues(alpha: 0.06)
                      : context.palette.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text(movement.type.label, style: context.text.micro),
                    const Spacer(),
                    Text(
                      movement.isIncome
                          ? '+${CurrencyFormatter.format(movement.amount)}'
                          : '-${CurrencyFormatter.format(movement.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: movement.isIncome
                            ? context.palette.success
                            : context.palette.danger,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Actions. C253 : l'une sous l'autre en largeur téléphone, libellés
          // lisibles en entier.
          ResponsiveActions(
            children: [
              SecondaryButton(
                label: '📊 Rapport',
                onPressed: () => context.push('/cash/report'),
              ),
              SecondaryButton(
                label: '📋 Historique',
                onPressed: () => context.push('/cash/history'),
              ),
              PrimaryButton(
                label: '🔒 Fermer la caisse',
                onPressed: () => _confirmClose(provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoSession(CashProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: context.palette.veil(0.24),
          ),
          const SizedBox(height: 16),
          Text('Aucune caisse ouverte', style: context.text.heading3),
          const SizedBox(height: 8),
          Text('Ouvrez une session pour commencer', style: context.text.body2),
          const SizedBox(height: 24),
          PrimaryButton(
            label: '🟢 Ouvrir la caisse',
            onPressed: () => _showOpenDialog(context, provider),
            // C268 : sur toute la largeur en téléphone ; à 200 px, le libellé
            // était coupé avec une police agrandie.
            width: isCompactWidth(context) ? double.infinity : 200,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: context.text.micro)),
          Expanded(child: Text(value, style: context.text.body2)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int? amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // C268 : libellé à gauche, qui rétrécit plutôt que de couper un mot
          // (« Remboursements ») ; le montant reste entier.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: isTotal ? context.text.body1 : context.text.body2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount == null ? '—' : CurrencyFormatter.format(amount),
            style: isTotal
                ? const TextStyle(fontWeight: FontWeight.w700)
                : null,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showOpenDialog(
    BuildContext context,
    CashProvider provider, {
    String initial = '',
  }) {
    final controller = TextEditingController(text: initial);
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('🟢 Ouvrir la caisse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fonds de caisse (GNF)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // C267 : « 10000 » ou « 10 000 », avec ou sans « GNF ».
              final amount = CurrencyFormatter.parse(controller.text);
              if (amount == null || amount < 0) return;
              final userId = context.read<AuthProvider>().userId;
              if (userId == null) return;
              final pharmacyId = context.read<AuthProvider>().pharmacyId;
              if (pharmacyId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucune officine rattachée à ce compte'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              // C273 (a) : le fonds saisi est confirmé avant d'être enregistré ;
              // « Corriger » ramène à la saisie, avec le montant tapé.
              final confirmed = await _confirmOpening(context, amount);
              if (!context.mounted) return;
              if (!confirmed) {
                _showOpenDialog(context, provider, initial: controller.text);
                return;
              }
              final success = await provider.openSession(
                pharmacyId: pharmacyId,
                cashierId: userId,
                openingBalance: amount,
                notes: notesController.text.trim(),
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Caisse ouverte avec succès'),
                    backgroundColor: context.palette.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.success,
              foregroundColor: context.palette.onPrimary,
            ),
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }

  /// C258 : le solde attendu est relu juste avant d'ouvrir le message de
  /// fermeture : c'est le chiffre que le caissier compare à son tiroir.
  Future<void> _confirmClose(CashProvider provider) async {
    final sessionId = provider.currentSession?.id;
    if (sessionId == null) return;
    await provider.refreshSummary(sessionId);
    if (!mounted) return;
    _showCloseDialog(context, provider);
  }

  void _showCloseDialog(
    BuildContext context,
    CashProvider provider, {
    String initial = '',
  }) {
    final expected = provider.currentExpectedCash;
    final controller = TextEditingController(text: initial);
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('🔒 Fermer la caisse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Solde attendu : ${expected == null ? '—' : CurrencyFormatter.format(expected)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Solde réel (GNF)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // C267 : « 10000 » ou « 10 000 », avec ou sans « GNF ».
              final amount = CurrencyFormatter.parse(controller.text);
              if (amount == null || amount < 0) return;
              final sessionId = provider.currentSession?.id;
              if (sessionId == null) return;
              Navigator.pop(ctx);
              // C273 (a) : attendu, compté et écart confirmés avant la
              // fermeture, qui ne se modifie plus ensuite ; « Recompter »
              // ramène à la saisie, avec le montant tapé.
              final confirmed = await _confirmClosing(
                context,
                expected: expected,
                counted: amount,
              );
              if (!context.mounted) return;
              if (!confirmed) {
                _showCloseDialog(context, provider, initial: controller.text);
                return;
              }
              final success = await provider.closeSession(
                sessionId: sessionId,
                closingBalance: amount,
                notes: notesController.text.trim(),
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Caisse fermée avec succès'),
                    backgroundColor: context.palette.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.warning,
              foregroundColor: context.palette.onPrimary,
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// C273 (a) : confirmation du fonds de caisse avant l'ouverture. Vrai si
  /// le caissier confirme, faux s'il veut corriger.
  Future<bool> _confirmOpening(BuildContext context, int amount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Confirmer l\'ouverture'),
        content: Text(
          'Fonds de caisse : ${CurrencyFormatter.format(amount)}\n\n'
          'Vérifiez le montant avant de confirmer.',
          style: context.text.body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Corriger'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// C273 (a) : confirmation de la fermeture : attendu, compté, écart. Un
  /// écart non nul invite à recompter le tiroir. Vrai si le caissier
  /// confirme, faux s'il veut recompter ou corriger.
  Future<bool> _confirmClosing(
    BuildContext context, {
    required int? expected,
    required int counted,
  }) async {
    final difference = expected == null ? null : counted - expected;
    final hasGap = difference != null && difference != 0;
    final gap = difference == null
        ? '—'
        : '${difference > 0 ? '+' : ''}${CurrencyFormatter.format(difference)}';
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Confirmer la fermeture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solde attendu : ${expected == null ? '—' : CurrencyFormatter.format(expected)}',
              style: context.text.body1,
            ),
            Text(
              'Solde compté : ${CurrencyFormatter.format(counted)}',
              style: context.text.body1,
            ),
            Text(
              'Écart : $gap',
              style: context.text.body1.copyWith(
                fontWeight: FontWeight.w600,
                color: hasGap ? context.palette.danger : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasGap
                  ? 'L\'écart n\'est pas nul. Recomptez le tiroir avant de '
                        'confirmer : une caisse fermée ne se modifie plus.'
                  : 'Une caisse fermée ne se modifie plus.',
              style: context.text.body2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(hasGap ? 'Recompter' : 'Corriger'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
