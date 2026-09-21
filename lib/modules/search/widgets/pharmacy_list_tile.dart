import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/availability_result.dart';

class PharmacyListTile extends StatelessWidget {
  final PharmacyStock stock;
  final VoidCallback? onTap;

  const PharmacyListTile({super.key, required this.stock, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pharmacy = stock.pharmacy;
    final isAvailable = stock.isAvailable;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          border: Border.all(
            color: isAvailable
                ? PharmaConnectColors.accentGreen.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            // Statut
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isAvailable
                    ? PharmaConnectColors.accentGreen
                    : Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name,
                    style: PharmaConnectTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    pharmacy.address,
                    style: PharmaConnectTypography.body2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (pharmacy.isOpenNow) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: PharmaConnectColors.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ouvert',
                          style: PharmaConnectTypography.micro.copyWith(
                            color: PharmaConnectColors.accentGreen,
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Fermé',
                          style: PharmaConnectTypography.micro.copyWith(
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
                      ],
                      if (pharmacy.isOpen24h) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PharmaConnectColors.accentCyan.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '24h/24',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: PharmaConnectColors.accentCyan,
                            ),
                          ),
                        ),
                      ],
                      if (pharmacy.isOnDuty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PharmaConnectColors.accentOrange
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Garde',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: PharmaConnectColors.accentOrange,
                            ),
                          ),
                        ),
                      ],
                      if (pharmacy.distance != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          pharmacy.distanceFormatted,
                          style: PharmaConnectTypography.micro,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Prix & stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isAvailable) ...[
                  Text(
                    CurrencyFormatter.format(stock.price),
                    style: PharmaConnectTypography.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: PharmaConnectColors.accentCyan,
                    ),
                  ),
                  // RG-REC-02 (audit Module 2, 29/08/2026) : « le prix
                  // affiché est indicatif tant que la pharmacie n'a pas
                  // confirmé la réservation ». Rien ne le signalait jusqu'ici
                  // — le prix apparaissait comme définitif.
                  Text(
                    'Prix indicatif',
                    style: PharmaConnectTypography.micro.copyWith(
                      color: PharmaConnectColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: stock.stockColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stock.stockLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: stock.stockColor,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentRed.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Rupture',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PharmaConnectColors.accentRed,
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
}
