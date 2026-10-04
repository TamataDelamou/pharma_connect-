import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/theme/palette.dart';

class WalletBalanceCard extends StatelessWidget {
  final int balance;
  final String? userName;
  // Bug corrigé (audit Module 8, 29/08/2026) : ce widget affichait des
  // valeurs fictives codées en dur (3400 pour le cashback, 12000 pour "en
  // attente"), totalement déconnectées de Wallet.cashbackAvailable /
  // Wallet.pendingBalance — champs pourtant présents sur le modèle mais
  // jamais transmis par wallet_screen.dart.
  final int cashbackAvailable;
  final int pendingBalance;
  final VoidCallback? onTopUp;
  final VoidCallback? onHistory;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    this.userName,
    this.cashbackAvailable = 0,
    this.pendingBalance = 0,
    this.onTopUp,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glow: true,
      glowColor: context.palette.secondary,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: context.palette.secondary,
              ),
              const SizedBox(width: 8),
              Text('Portefeuille GSG', style: context.text.heading3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.palette.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: context.palette.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '⚡ Kernel',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: context.palette.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance),
            style: context.text.kpiLarge.copyWith(
              color: context.palette.secondary,
            ),
          ),
          const SizedBox(height: 4),
          if (userName != null) ...[
            Text('Bienvenue, $userName', style: context.text.body2),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTopUp,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: context.palette.secondary.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Approvisionner'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.secondary,
                    foregroundColor: context.palette.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Historique'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('Cashback', style: context.text.micro),
                      Text(
                        CurrencyFormatter.format(cashbackAvailable),
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.palette.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('En attente', style: context.text.micro),
                      Text(
                        CurrencyFormatter.format(pendingBalance),
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.palette.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
