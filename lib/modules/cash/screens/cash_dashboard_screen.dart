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
                        color: context.palette.success,
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
                        color: context.palette.danger,
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

          // Summary
          if (provider.summary != null) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Résumé', style: context.text.heading3),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Ventes',
                    provider.summary!['total_sales'] as int? ?? 0,
                  ),
                  _buildSummaryRow(
                    'Remboursements',
                    provider.summary!['total_refunds'] as int? ?? 0,
                  ),
                  _buildSummaryRow(
                    'Dépôts',
                    provider.summary!['total_deposits'] as int? ?? 0,
                  ),
                  _buildSummaryRow(
                    'Retraits',
                    provider.summary!['total_withdrawals'] as int? ?? 0,
                  ),
                  Divider(color: context.palette.veil(0.12)),
                  _buildSummaryRow(
                    'Solde attendu',
                    session.expectedBalance ?? 0,
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

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

          // Actions
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: '📊 Rapport',
                  onPressed: () => context.push('/cash/report'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: '📋 Historique',
                  onPressed: () => context.push('/cash/history'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: '🔒 Fermer la caisse',
                  onPressed: () => _showCloseDialog(context, provider),
                ),
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
            width: 200,
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

  Widget _buildSummaryRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: isTotal ? context.text.body1 : context.text.body2),
          const Spacer(),
          Text(
            CurrencyFormatter.format(amount),
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

  void _showOpenDialog(BuildContext context, CashProvider provider) {
    final controller = TextEditingController();
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
              final amount = int.tryParse(controller.text);
              if (amount == null || amount < 0) return;
              final userId = SupabaseService().currentUser?.id;
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
              foregroundColor: context.palette.textPrimary,
            ),
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }

  void _showCloseDialog(BuildContext context, CashProvider provider) {
    final controller = TextEditingController();
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
              'Solde attendu: ${CurrencyFormatter.format(provider.currentSession?.expectedBalance ?? 0)}',
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
              final amount = int.tryParse(controller.text);
              if (amount == null || amount < 0) return;
              final sessionId = provider.currentSession?.id;
              if (sessionId == null) return;
              Navigator.pop(ctx);
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
              foregroundColor: context.palette.textPrimary,
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
