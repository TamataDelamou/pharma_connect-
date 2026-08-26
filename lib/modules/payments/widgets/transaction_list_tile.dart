import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/transaction.dart';
import '../models/payment_method.dart';

class TransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final bool showStatus;

  const TransactionListTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: transaction.statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                transaction.method == PaymentMethod.gsgWallet
                    ? Icons.account_balance_wallet
                    : transaction.method.isMobileMoney
                    ? Icons.phone_android
                    : transaction.method == PaymentMethod.bankCard
                    ? Icons.credit_card
                    : Icons.payments,
                color: transaction.statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.pharmacyName ?? 'Transaction',
                    style: PharmaConnectTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '#${transaction.id} • ${transaction.method.label}',
                    style: PharmaConnectTypography.body2,
                  ),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: PharmaConnectTypography.micro,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.finalAmount > 0 ? "+" : ""}${CurrencyFormatter.format(transaction.finalAmount)}',
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w700,
                    color: transaction.isCompleted
                        ? PharmaConnectColors.accentGreen
                        : transaction.isFailed
                        ? PharmaConnectColors.accentRed
                        : PharmaConnectColors.textPrimary,
                  ),
                ),
                if (showStatus) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: transaction.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: transaction.statusColor,
                      ),
                    ),
                  ),
                ],
              ],
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
