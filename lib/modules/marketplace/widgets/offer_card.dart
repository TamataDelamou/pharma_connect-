import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../models/b2b_offer.dart';

/// Audit Module 13 (B2B, 29/08/2026) : `marketplace_home_screen.dart`
/// importait `../widgets/offer_card.dart` et utilisait `OfferCard` alors
/// qu'aucun fichier ni classe de ce nom n'existait nulle part dans le
/// projet (import mort — aucun dossier `widgets/` sous `marketplace/`) :
/// erreur de compilation bloquante pour tout l'écran d'accueil du module.
/// Créé ici en suivant le patron visuel déjà établi par `DeliveryCard`
/// (Module 7, `GlassCard` + thème PharmaConnect).
class OfferCard extends StatelessWidget {
  final B2BOffer offer;
  final VoidCallback? onTap;

  /// Audit Module 13 (B2B, 29/08/2026, clôture) : réserve levée —
  /// `deleteOffer()` (MarketplaceService/MarketplaceProvider) était
  /// fonctionnel mais orphelin (jamais relié à l'UI). `onDelete` reste
  /// optionnel et n'est fourni que par l'onglet « Mes offres »
  /// (marketplace_home_screen.dart) : un vendeur ne doit pouvoir supprimer
  /// que ses propres offres, jamais depuis le catalogue global.
  final VoidCallback? onDelete;

  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.productName,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (offer.isActive
                          ? PharmaConnectColors.accentGreen
                          : PharmaConnectColors.accentRed)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  offer.isActive ? 'Active' : offer.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: offer.isActive
                        ? PharmaConnectColors.accentGreen
                        : PharmaConnectColors.accentRed,
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: PharmaConnectColors.accentRed,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.storefront, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  offer.sellerName ?? 'Officine partenaire',
                  style: PharmaConnectTypography.micro,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(offer.price),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PharmaConnectColors.accentCyan,
                ),
              ),
              Text(
                '${offer.quantity} ${offer.unit} dispo. · min ${offer.minOrderQuantity}',
                style: PharmaConnectTypography.micro,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
