import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/stock_batch.dart';

class StockBatchTile extends StatelessWidget {
  final StockBatch batch;
  final bool showActions;
  final VoidCallback? onTap;

  const StockBatchTile({
    super.key,
    required this.batch,
    this.showActions = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: batch.isExpired
                ? PharmaConnectColors.accentRed.withValues(alpha: 0.3)
                : batch.isExpiringSoon
                ? PharmaConnectColors.accentOrange.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lot #${batch.batchNumber}',
                    style: PharmaConnectTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (batch.isExpired) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentRed.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Périmé',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: PharmaConnectColors.accentRed,
                      ),
                    ),
                  ),
                ] else if (batch.isExpiringSoon) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentOrange.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Bientôt périmé',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: PharmaConnectColors.accentOrange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Péremption : ${_formatDate(batch.expiryDate)}',
                  style: PharmaConnectTypography.body2,
                ),
                const Spacer(),
                Text(
                  '${batch.quantity} unités',
                  style: PharmaConnectTypography.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (batch.quantityReserved > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${batch.quantityReserved} réservés',
                style: PharmaConnectTypography.micro.copyWith(
                  color: PharmaConnectColors.accentCyan,
                ),
              ),
            ],
            if (batch.supplierName != null) ...[
              const SizedBox(height: 2),
              Text(
                'Fournisseur : ${batch.supplierName}',
                style: PharmaConnectTypography.micro,
              ),
            ],
            if (batch.purchasePriceInt > 0) ...[
              Text(
                'Prix d\'achat : ${CurrencyFormatter.format(batch.purchasePriceInt)}',
                style: PharmaConnectTypography.micro,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
