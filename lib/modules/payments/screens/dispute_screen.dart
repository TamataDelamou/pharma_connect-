import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/transaction_status.dart';
import '../providers/payment_provider.dart';

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedTransactionId;

  // Correctif (audit Module 8, 29/08/2026) : appel non filtré — fonctionnait
  // par accident via RLS (transactions_select_own), mais sans expliciter
  // l'utilisateur comme les autres écrans du module. Corrigé par cohérence
  // et parce que la nouvelle policy transactions_staff_select (migration
  // 20260829019000) élargit désormais ce que RLS peut renvoyer sans filtre.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      context.read<PaymentProvider>().loadTransactions(userId: userId);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

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
                    'Litiges de paiement',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Signalez un problème avec une transaction',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Transactions récentes éligibles
                    if (provider.transactions.isNotEmpty) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transactions récentes',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 8),
                            ...provider.transactions
                                .where(
                                  (t) =>
                                      t.status == TransactionStatus.completed ||
                                      t.status == TransactionStatus.processing,
                                )
                                .take(5)
                                .map(
                                  (t) => ListTile(
                                    title: Text(
                                      '#${t.id} - ${t.pharmacyName ?? 'Pharmacie'}',
                                      style: PharmaConnectTypography.body1,
                                    ),
                                    subtitle: Text(
                                      '${CurrencyFormatter.format(t.amount)} • ${_formatDate(t.createdAt)}',
                                      style: PharmaConnectTypography.body2,
                                    ),
                                    selected: _selectedTransactionId == t.id,
                                    selectedColor: PharmaConnectColors
                                        .accentCyan
                                        .withValues(alpha: 0.1),
                                    onTap: () => setState(
                                      () => _selectedTransactionId = t.id,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Formulaire de signalement
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Signaler un litige',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 16),

                          GlassInput(
                            label: 'Raison du litige',
                            hint:
                                'Ex: Paiement non reconnu, montant incorrect...',
                            controller: _reasonController,
                            prefixIcon: Icons.warning,
                          ),
                          const SizedBox(height: 16),

                          GlassInput(
                            label: 'Description détaillée',
                            hint: 'Expliquez en détail le problème...',
                            controller: _descriptionController,
                            prefixIcon: Icons.description,
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: PharmaConnectColors.accentOrange
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: PharmaConnectColors.accentOrange
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: PharmaConnectColors.accentOrange,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Un litige sera traité sous 48h. Vous serez notifié de l\'évolution.',
                                    style: PharmaConnectTypography.micro
                                        .copyWith(
                                          color:
                                              PharmaConnectColors.textSecondary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Soumettre le litige',
                      icon: Icons.send,
                      onPressed: _selectedTransactionId == null
                          ? null
                          : () async {
                              if (_reasonController.text.trim().isEmpty ||
                                  _descriptionController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Veuillez remplir tous les champs',
                                    ),
                                    backgroundColor:
                                        PharmaConnectColors.accentRed,
                                  ),
                                );
                                return;
                              }

                              // Bug corrigé (audit Module 8, 29/08/2026) :
                              // _descriptionController était validé comme
                              // obligatoire dans l'UI mais jamais transmis
                              // à markAsDisputed — seul reason était envoyé,
                              // la description saisie par le patient était
                              // silencieusement perdue.
                              final success = await provider.markAsDisputed(
                                _selectedTransactionId!,
                                reason:
                                    '${_reasonController.text.trim()} — '
                                    '${_descriptionController.text.trim()}',
                              );

                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Litige soumis avec succès'),
                                    backgroundColor:
                                        PharmaConnectColors.accentGreen,
                                  ),
                                );
                                context.pop();
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
