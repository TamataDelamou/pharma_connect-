import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/profile_service.dart';
import '../models/payment_method.dart';
import '../providers/payment_provider.dart';
import '../widgets/transaction_list_tile.dart';
import '../widgets/wallet_balance_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ProfileService _profileService = ProfileService();
  final OfflineSyncService _offlineSync = OfflineSyncService();
  String? _userName;

  // Bug corrigé (audit Module 8, 29/08/2026) : 'patient_123' en dur pour
  // loadWallet ET loadTransactions — 3e/4e occurrence de ce défaut dans ce
  // seul écran (voir aussi 'Jean Dupont' plus bas). Ces appels
  // n'atteignaient jamais les vraies données de l'utilisateur connecté.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final userId = auth.userId;
      if (userId == null) return;
      final provider = context.read<PaymentProvider>();
      provider.loadWallet(userId);
      provider.loadTransactions(userId: userId);
      final fullName = await _profileService.getFullName(userId);
      if (mounted) {
        setState(() {
          _userName = fullName ?? auth.userEmail ?? auth.userPhone;
        });
      }
    });
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
            // En-tête
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
                      'Portefeuille GSG',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                OutlinedButton.icon(
                  onPressed: () => _showTopUpDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Recharger'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Gérez votre portefeuille et vos transactions',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),

            // Mode hors-ligne (directive standing, lecture seule — audit
            // Module 8, 29/08/2026) : voir OfflineSyncService pour la
            // justification de ne pas étendre ce repli aux écritures.
            if (provider.isOffline) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: PharmaConnectColors.accentAmber.withValues(alpha: 0.1),
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
                      Icons.wifi_off,
                      color: PharmaConnectColors.accentAmber,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error ??
                            'Hors connexion — dernières données synchronisées affichées.',
                        style: PharmaConnectTypography.micro,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (provider.isLoading) ...[
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ] else if (provider.wallet != null) ...[
              // Solde
              WalletBalanceCard(
                balance: provider.wallet!.balance,
                userName: _userName,
                cashbackAvailable: provider.wallet!.cashbackAvailable,
                pendingBalance: provider.wallet!.pendingBalance,
                onTopUp: () => _showTopUpDialog(context),
                onHistory: () => context.go('/transactions'),
              ),
              const SizedBox(height: 16),

              // Dernières transactions
              const Text(
                'Dernières transactions',
                style: PharmaConnectTypography.heading3,
              ),
              const SizedBox(height: 8),

              Expanded(
                child: provider.transactions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.white24,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Aucune transaction',
                              style: PharmaConnectTypography.body2,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.transactions.take(10).length,
                        itemBuilder: (context, index) {
                          final transaction = provider.transactions[index];
                          return TransactionListTile(
                            transaction: transaction,
                            onTap: () {
                              context.push('/transactions/${transaction.id}');
                            },
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

  void _showTopUpDialog(BuildContext context) {
    final amountController = TextEditingController();
    final List<PaymentMethod> methods = [
      PaymentMethod.orangeMoney,
      PaymentMethod.mtnMomo,
      PaymentMethod.moovMoney,
      PaymentMethod.bankCard,
    ];
    PaymentMethod selectedMethod = PaymentMethod.orangeMoney;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Recharger le portefeuille'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText:
                        'Montant (${CurrencyFormatter.defaultCurrencyCode})',
                    border: OutlineInputBorder(),
                    prefixText: '${CurrencyFormatter.defaultCurrencyCode} ',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Moyen de paiement'),
                const SizedBox(height: 8),
                ...methods.map((method) {
                  final isSelected = selectedMethod == method;
                  return GestureDetector(
                    onTap: () => setState(() => selectedMethod = method),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? PharmaConnectColors.accentCyan.withValues(
                                alpha: 0.1,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? PharmaConnectColors.accentCyan
                              : Colors.white.withValues(alpha: 0.06),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            method.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(method.label)),
                          if (isSelected) ...[
                            const Icon(
                              Icons.check_circle,
                              color: PharmaConnectColors.accentCyan,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Montant invalide')),
                );
                return;
              }
              final userId = context.read<AuthProvider>().userId;
              if (userId == null) return;
              // Décision D13 (audit Module 8, 29/08/2026, arbitrée par le
              // porteur du projet) : recharge de portefeuille bloquée
              // explicitement hors connexion, même logique que
              // payment_screen.dart.
              final hasInternet = await _offlineSync.hasInternet();
              if (!hasInternet) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Recharge indisponible hors connexion. '
                        'Reconnectez-vous pour recharger votre portefeuille.',
                      ),
                      backgroundColor: PharmaConnectColors.accentRed,
                    ),
                  );
                }
                return;
              }
              Navigator.pop(context);
              final success = await context.read<PaymentProvider>().topUpWallet(
                userId: userId,
                amount: amount,
                method: selectedMethod,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Portefeuille rechargé avec succès !'),
                    backgroundColor: PharmaConnectColors.accentGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Recharger'),
          ),
        ],
      ),
    );
  }
}
