import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/transaction.dart';
import '../models/payment_method.dart';
import '../../../core/theme/palette.dart';

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
          color: context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.palette.surfaceMuted, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: transaction.statusColor
                    .of(context.palette)
                    .withValues(alpha: 0.15),
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
                color: transaction.statusColor.of(context.palette),
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
                    style: context.text.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '#${transaction.id} • ${transaction.method.label}',
                    style: context.text.body2,
                  ),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: context.text.micro,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.finalAmount > 0 ? "+" : ""}${CurrencyFormatter.format(transaction.finalAmount)}',
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w700,
                    color: transaction.isCompleted
                        ? context.palette.success
                        : transaction.isFailed
                        ? context.palette.danger
                        : context.palette.textPrimary,
                  ),
                ),
                if (showStatus) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: transaction.statusColor
                          .of(context.palette)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: transaction.statusColor.of(context.palette),
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
