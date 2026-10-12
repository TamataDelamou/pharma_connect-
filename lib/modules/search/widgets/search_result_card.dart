import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/search_result.dart';
import 'availability_badge.dart';
import '../../../core/theme/palette.dart';

class SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;
  final bool showAvailability;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.onTap,
    this.showAvailability = true,
  });

  @override
  Widget build(BuildContext context) {
    final product = result.product;
    final hasStock = result.isAvailable;
    final bestPrice = result.bestPrice;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Image
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.palette.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication,
              color: context.palette.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.genericName,
                  style: context.text.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // C253 : les mentions passent à la ligne au lieu de déborder.
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${product.dosage} • ${product.form}',
                      style: context.text.micro,
                    ),
                    if (product.isGeneric) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.secondary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Générique',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: context.palette.secondary,
                          ),
                        ),
                      ),
                    ],
                    if (product.isPrescriptionRequired) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.warning.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Ordonnance',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: context.palette.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Prix et disponibilité
          if (showAvailability) ...[
            const SizedBox(width: 8),
            // C253 : colonne bornée. Sans borne, le nom de l'officine la plus
            // proche n'était jamais coupé et poussait la carte hors de
            // l'écran.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 124),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (bestPrice != null) ...[
                    Text(
                      CurrencyFormatter.format(bestPrice),
                      style: context.text.body1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.palette.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  AvailabilityBadge(
                    isAvailable: hasStock,
                    count: result.availableCount,
                  ),
                  if (result.nearestPharmacy != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${result.nearestPharmacy}',
                      style: context.text.micro,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
