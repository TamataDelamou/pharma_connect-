import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/search_result.dart';
import 'availability_badge.dart';

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
              color: PharmaConnectColors.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication,
              color: PharmaConnectColors.accentCyan,
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
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.genericName,
                  style: PharmaConnectTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '${product.dosage} • ${product.form}',
                      style: PharmaConnectTypography.micro,
                    ),
                    if (product.isGeneric) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentPurple.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Générique',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: PharmaConnectColors.accentPurple,
                          ),
                        ),
                      ),
                    ],
                    if (product.isPrescriptionRequired) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentOrange.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Ordonnance',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: PharmaConnectColors.accentOrange,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (bestPrice != null) ...[
                  Text(
                    CurrencyFormatter.format(bestPrice),
                    style: PharmaConnectTypography.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: PharmaConnectColors.accentCyan,
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
                    style: PharmaConnectTypography.micro,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
