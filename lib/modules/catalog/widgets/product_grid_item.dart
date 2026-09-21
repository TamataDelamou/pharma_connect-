import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../shared/models/product.dart';
import 'product_image.dart';

class ProductGridItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductGridItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audit Module 3 (29/08/2026) : un widget ProductImage dédié
          // existait déjà (avec placeholder/gestion d'erreur) mais n'était
          // consommé nulle part — cette grille affichait toujours une icône
          // générique, même quand products.image_url est renseigné.
          ProductImage(
            imageUrl: product.imageUrl,
            productName: product.name,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            product.name,
            style: PharmaConnectTypography.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            product.genericName,
            style: PharmaConnectTypography.body2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${product.dosage} • ${product.form}',
            style: PharmaConnectTypography.micro,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Badges
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (product.isGeneric)
                _buildBadge('Générique', PharmaConnectColors.accentPurple),
              if (product.isPrescriptionRequired)
                _buildBadge('Ordonnance', PharmaConnectColors.accentOrange),
              if (!product.isPrescriptionRequired)
                _buildBadge('Libre', PharmaConnectColors.accentGreen),
              // RG-CAT-02 : ce badge ne peut visuellement apparaître que
              // pour un utilisateur déjà autorisé à voir ce produit (la RLS
              // le retire du flux réseau pour un patient) — il informe le
              // personnel opérationnel du statut réglementaire renforcé.
              if (product.isControlledSubstance)
                _buildBadge('Stupéfiant/Psychotrope', PharmaConnectColors.accentRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
