import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/text/whole_words_text.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/stock_batch.dart';
import '../../../core/theme/palette.dart';

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
          color: context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: batch.isExpired
                ? context.palette.danger.withValues(alpha: 0.3)
                : batch.isExpiringSoon
                ? context.palette.warning.withValues(alpha: 0.3)
                : context.palette.surface,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: WholeWordsText(
                    'Lot #${batch.batchNumber}',
                    style: context.text.body1.copyWith(
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
                      color: context.palette.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Périmé',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.palette.onTint(context.palette.danger),
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
                      color: context.palette.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Bientôt périmé',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        // C272 : texte de pastille d'état par onTint (C265),
                        // comme toutes les pastilles d'état.
                        color: context.palette.onTint(context.palette.warning),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // C272 : la quantité passe à la ligne quand la place manque
            // (débordement de 5,4 px avec une police agrandie) ; la date de
            // péremption, d'un seul tenant, n'est jamais coupée.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 2,
              children: [
                Text(
                  'Péremption : ${_formatDate(batch.expiryDate)}',
                  style: context.text.body2,
                ),
                Text(
                  '${batch.quantity} unités',
                  style: context.text.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (batch.quantityReserved > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${batch.quantityReserved} réservés',
                style: context.text.micro.copyWith(
                  color: context.palette.primary,
                ),
              ),
            ],
            if (batch.supplierName != null) ...[
              const SizedBox(height: 2),
              Text(
                'Fournisseur : ${batch.supplierName}',
                style: context.text.micro,
              ),
            ],
            if (batch.purchasePriceInt > 0) ...[
              Text(
                'Prix d\'achat : ${CurrencyFormatter.format(batch.purchasePriceInt)}',
                style: context.text.micro,
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
