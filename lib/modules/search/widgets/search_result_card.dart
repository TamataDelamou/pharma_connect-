import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/search_result.dart';
import 'availability_badge.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/layout/responsive.dart';

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

    // Image
    final image = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: context.palette.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.medication, color: context.palette.primary, size: 28),
    );

    // Infos
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: context.text.body1.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2, // C265 : nom ou adresse, 2 lignes au plus.
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          product.genericName,
          style: context.text.body2,
          maxLines: 2, // C265 : nom ou adresse, 2 lignes au plus.
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.palette.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Générique',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: context.palette.onTint(context.palette.secondary),
                  ),
                ),
              ),
            ],
            if (product.isPrescriptionRequired) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.palette.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Ordonnance',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: context.palette.onTint(context.palette.warning),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    // Prix et disponibilité.
    Widget availability({required bool compact}) => Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        if (compact)
          // C268 : sous le nom en largeur téléphone, prix et disponibilité
          // côte à côte, qui passent à la ligne au besoin.
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (bestPrice != null) _price(context, bestPrice),
              AvailabilityBadge(
                isAvailable: hasStock,
                count: result.availableCount,
              ),
            ],
          )
        else ...[
          if (bestPrice != null) ...[
            _price(context, bestPrice),
            const SizedBox(height: 4),
          ],
          AvailabilityBadge(
            isAvailable: hasStock,
            count: result.availableCount,
          ),
        ],
        if (result.nearestPharmacy != null) ...[
          const SizedBox(height: 4),
          Text(
            '📍 ${result.nearestPharmacy}',
            style: context.text.micro,
            maxLines: 2, // C265 : nom ou adresse, 2 lignes au plus.
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    // C268 : en largeur téléphone, le prix et la disponibilité passent sous
    // le nom. À côté, ils prenaient jusqu'à 124 px et, avec une police
    // agrandie, le nom du produit était coupé au milieu d'un mot.
    final compact = isCompactWidth(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(width: 12),
                    Expanded(child: info),
                  ],
                ),
                if (showAvailability) ...[
                  const SizedBox(height: 12),
                  availability(compact: true),
                ],
              ],
            )
          : Row(
              children: [
                image,
                const SizedBox(width: 12),
                Expanded(child: info),
                if (showAvailability) ...[
                  const SizedBox(width: 8),
                  // C253 : colonne bornée. Sans borne, le nom de l'officine
                  // la plus proche n'était jamais coupé et poussait la carte
                  // hors de l'écran.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 124),
                    child: availability(compact: false),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _price(BuildContext context, int price) => Text(
    CurrencyFormatter.format(price),
    style: context.text.body1.copyWith(
      fontWeight: FontWeight.w700,
      color: context.palette.primary,
    ),
  );
}
