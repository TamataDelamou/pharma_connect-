import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/cash_provider.dart';
import '../models/cash_drawer_session.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class CashHistoryScreen extends StatefulWidget {
  const CashHistoryScreen({super.key});

  @override
  State<CashHistoryScreen> createState() => _CashHistoryScreenState();
}

class _CashHistoryScreenState extends State<CashHistoryScreen> {
  int _selectedRange = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessions();
    });
  }

  void _loadSessions() {
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) return;
    // C273 (c) : la rectification est réservée au titulaire.
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<CashProvider>().ensureManager(
        userId: userId,
        pharmacyId: pharmacyId,
      );
    }
    final now = DateTime.now();
    context.read<CashProvider>().loadSessions(
      pharmacyId: pharmacyId,
      fromDate: now.subtract(Duration(days: _selectedRange)),
      toDate: now,
    );
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
                      '📋 Historique de caisse',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 16),

            // C268 : les puces passent à la ligne avec une police agrandie.
            Wrap(
              runSpacing: 8,
              children: [7, 30, 90].map((days) {
                final selected = _selectedRange == days;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$days jours'),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedRange = days);
                      _loadSessions();
                    },
                    selectedColor: context.palette.primary.withValues(
                      alpha: 0.2,
                    ),
                    // C265 : puce choisie, texte foncé sur fond teinté
                    // (4,5:1).
                    labelStyle: TextStyle(
                      color: selected
                          ? context.palette.onTint(context.palette.primary)
                          : context.palette.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CashProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.palette.danger),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: context.text.body2.copyWith(color: context.palette.danger),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                _loadSessions();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucune session de caisse', style: context.text.heading3),
            SizedBox(height: 8),
            Text(
              'Les sessions de caisse fermées apparaîtront ici',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.sessions.length,
      itemBuilder: (context, index) {
        final session = provider.sessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(session.status),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatDate(session.openedAt),
                            style: context.text.body1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                session.status,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              session.status.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _statusColor(session.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        session.cashierName ?? session.cashierId,
                        style: context.text.body2,
                      ),
                      Text(
                        'Ouverture ${CurrencyFormatter.format(session.openingBalance)}'
                        '${session.closingBalance != null ? ' • Clôture ${CurrencyFormatter.format(session.closingBalance!)}' : ''}',
                        style: context.text.micro,
                      ),
                      // C273 (c) : la dernière rectification fait foi ; la
                      // fermeture d'origine reste affichée au-dessus.
                      if (session.latestRectification case final r?)
                        Text(
                          'Rectifiée : ${CurrencyFormatter.format(r.countedBalance)}'
                          ' • écart ${_signed(r.difference)}'
                          '${session.rectifications.length > 1 ? ' (${session.rectifications.length} rectifications)' : ''}',
                          style: context.text.micro.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.palette.textPrimary,
                          ),
                        ),
                      if (provider.canRectify(session))
                        TextButton(
                          onPressed: () =>
                              _showRectifyDialog(provider, session),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          child: const Text('Rectifier la fermeture'),
                        ),
                    ],
                  ),
                ),
                if (session.difference != null)
                  Text(
                    session.differenceLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: session.differenceColor.of(context.palette),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(CashSessionStatus status) {
    switch (status) {
      case CashSessionStatus.open:
        return context.palette.success;
      case CashSessionStatus.closed:
        return context.palette.textSecondary;
      case CashSessionStatus.suspended:
        return context.palette.warning;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// C273 (c) : écart signé (« +500 GNF », « −3 000 GNF », « 0 GNF »).
  String _signed(int amount) =>
      '${amount > 0 ? '+' : ''}${CurrencyFormatter.format(amount)}';

  /// C273 (c) : rectification d'une caisse fermée, par le titulaire. La
  /// fermeture d'origine n'est pas modifiée ; la rectification s'y rattache,
  /// avec son motif.
  void _showRectifyDialog(
    CashProvider provider,
    CashDrawerSession session, {
    String initialAmount = '',
    String initialReason = '',
  }) {
    final amountController = TextEditingController(text: initialAmount);
    final reasonController = TextEditingController(text: initialReason);
    final expected = session.expectedBalance;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Rectifier la fermeture'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solde attendu : ${expected == null ? '—' : CurrencyFormatter.format(expected)}',
                style: context.text.body1,
              ),
              Text(
                'Compté à la fermeture : '
                '${CurrencyFormatter.format(session.closingBalance ?? 0)}'
                '${session.difference == null ? '' : ' (écart ${_signed(session.difference!)})'}',
                style: context.text.body1,
              ),
              for (final r in session.rectifications)
                Text(
                  'Rectifié le ${_formatDate(r.createdAt)} : '
                  '${CurrencyFormatter.format(r.countedBalance)} '
                  '(écart ${_signed(r.difference)}) — ${r.reason}',
                  style: context.text.body2,
                ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant compté (GNF)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motif (obligatoire)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La fermeture d\'origine reste visible ; la rectification s\'y '
                'ajoute, avec son motif.',
                style: context.text.body2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = CurrencyFormatter.parse(amountController.text);
              final reason = reasonController.text.trim();
              if (amount == null || amount < 0 || reason.isEmpty) return;
              Navigator.pop(ctx);
              final confirmed = await _confirmRectification(
                expected: expected,
                counted: amount,
                reason: reason,
              );
              if (!mounted) return;
              if (!confirmed) {
                _showRectifyDialog(
                  provider,
                  session,
                  initialAmount: amountController.text,
                  initialReason: reasonController.text,
                );
                return;
              }
              final success = await provider.rectifyClosing(
                session: session,
                countedBalance: amount,
                reason: reason,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Rectification enregistrée'
                        : provider.error ?? 'Rectification impossible.',
                  ),
                  backgroundColor: success
                      ? context.palette.success
                      : context.palette.danger,
                ),
              );
            },
            child: const Text('Rectifier'),
          ),
        ],
      ),
    );
  }

  /// C273 (c) : confirmation de la rectification. Vrai si confirmée.
  Future<bool> _confirmRectification({
    required int? expected,
    required int counted,
    required String reason,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Confirmer la rectification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solde attendu : ${expected == null ? '—' : CurrencyFormatter.format(expected)}',
              style: context.text.body1,
            ),
            Text(
              'Montant compté : ${CurrencyFormatter.format(counted)}',
              style: context.text.body1,
            ),
            Text(
              'Écart : ${expected == null ? '—' : _signed(counted - expected)}',
              style: context.text.body1.copyWith(fontWeight: FontWeight.w600),
            ),
            Text('Motif : $reason', style: context.text.body1),
          ],
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
}
