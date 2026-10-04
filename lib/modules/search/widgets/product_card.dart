import 'package:flutter/material.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../shared/models/product.dart';
import '../../../core/theme/palette.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showStockIndicator;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showStockIndicator = true,
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
          // Icône ou image placeholder
          Container(
            width: 48,
            height: 48,
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
          const SizedBox(height: 12),
          // Nom
          Text(
            product.name,
            style: context.text.body1.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // DCI
          Text(
            product.genericName,
            style: context.text.body2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Dosage + forme
          Text(
            '${product.dosage} • ${product.form}',
            style: context.text.micro,
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
                _buildBadge('Générique', context.palette.secondary),
              if (product.isPrescriptionRequired)
                _buildBadge('Ordonnance', context.palette.warning),
              if (!product.isPrescriptionRequired)
                _buildBadge('Libre', context.palette.success),
            ],
          ),
          if (showStockIndicator) ...[
            const SizedBox(height: 8),
            // Indicateur de disponibilité (simulé)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.palette.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.palette.success,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Disponible en pharmacie',
                    style: context.text.micro.copyWith(
                      color: context.palette.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
