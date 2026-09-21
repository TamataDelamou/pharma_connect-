import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/cards/glass_card.dart';

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
      glowColor: PharmaConnectColors.accentPurple,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: PharmaConnectColors.accentPurple,
              ),
              const SizedBox(width: 8),
              const Text(
                'Portefeuille GSG',
                style: PharmaConnectTypography.heading3,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PharmaConnectColors.accentPurple.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: PharmaConnectColors.accentPurple.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: const Text(
                  '⚡ Kernel',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: PharmaConnectColors.accentPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance),
            style: PharmaConnectTypography.kpiLarge.copyWith(
              color: PharmaConnectColors.accentPurple,
            ),
          ),
          const SizedBox(height: 4),
          if (userName != null) ...[
            Text('Bienvenue, $userName', style: PharmaConnectTypography.body2),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTopUp,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: PharmaConnectColors.accentPurple.withValues(
                        alpha: 0.3,
                      ),
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
                    backgroundColor: PharmaConnectColors.accentPurple,
                    foregroundColor: PharmaConnectColors.textPrimary,
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
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Cashback',
                        style: PharmaConnectTypography.micro,
                      ),
                      Text(
                        CurrencyFormatter.format(cashbackAvailable),
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: PharmaConnectColors.accentGreen,
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
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'En attente',
                        style: PharmaConnectTypography.micro,
                      ),
                      Text(
                        CurrencyFormatter.format(pendingBalance),
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: PharmaConnectColors.accentOrange,
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
