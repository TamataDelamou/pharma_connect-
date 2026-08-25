import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentProvider>();
      provider.loadWallet('patient_123');
      provider.loadTransactions(userId: 'patient_123');
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
                    'Portefeuille GSG',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
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

            if (provider.isLoading) ...[
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ] else if (provider.wallet != null) ...[
              // Solde
              WalletBalanceCard(
                balance: provider.wallet!.balance,
                userName: 'Jean Dupont',
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
              Navigator.pop(context);
              final success = await context.read<PaymentProvider>().topUpWallet(
                userId: 'patient_123',
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
