import 'package:flutter/material.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/availability_result.dart';
import '../../../core/theme/palette.dart';

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
          color: context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          border: Border.all(
            color: isAvailable
                ? context.palette.success.withValues(alpha: 0.2)
                : context.palette.surface,
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
                    ? context.palette.success
                    : context.palette.textMuted,
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
                    style: context.text.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    pharmacy.address,
                    style: context.text.body2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // C253 : les mentions passent à la ligne au lieu de
                  // déborder (« Ouvert », « 24h/24 », « Garde », distance).
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pharmacy.isOpenNow
                                  ? context.palette.success
                                  : context.palette.danger,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pharmacy.isOpenNow ? 'Ouvert' : 'Fermé',
                            style: context.text.micro.copyWith(
                              color: pharmacy.isOpenNow
                                  ? context.palette.success
                                  : context.palette.danger,
                            ),
                          ),
                        ],
                      ),
                      if (pharmacy.isOpen24h) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.palette.primary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '24h/24',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: context.palette.primary,
                            ),
                          ),
                        ),
                      ],
                      if (pharmacy.isOnDuty) ...[
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
                            'Garde',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: context.palette.warning,
                            ),
                          ),
                        ),
                      ],
                      if (pharmacy.distance != null) ...[
                        Text(
                          pharmacy.distanceFormatted,
                          style: context.text.micro,
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
                    style: context.text.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.palette.primary,
                    ),
                  ),
                  // RG-REC-02 (audit Module 2, 29/08/2026) : « le prix
                  // affiché est indicatif tant que la pharmacie n'a pas
                  // confirmé la réservation ». Rien ne le signalait jusqu'ici
                  // — le prix apparaissait comme définitif.
                  Text(
                    'Prix indicatif',
                    style: context.text.micro.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: stock.stockColor
                          .of(context.palette)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stock.stockLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: stock.stockColor.of(context.palette),
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
                      color: context.palette.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Rupture',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.palette.danger,
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
