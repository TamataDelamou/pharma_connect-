import 'package:flutter/material.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/reservation_item.dart';
import '../../../core/theme/palette.dart';

class CartItemTile extends StatelessWidget {
  final ReservationItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
        border: Border.all(
          color: item.isSubstitution
              ? context.palette.secondary.withValues(alpha: 0.2)
              : context.palette.surface,
        ),
      ),
      // C245 : deux lignes (produit, puis quantité et total) : sur une seule,
      // le nom du produit disparaissait à 360 px.
      child: Column(
        children: [
          Row(
            children: [
              // Icône
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.palette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: context.palette.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: context.text.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2, // C265 : nom ou adresse, 2 lignes au plus.
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.dosage} • ${CurrencyFormatter.format(item.pricePerUnit)}',
                      style: context.text.body2,
                    ),
                    if (item.isSubstitution) ...[
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
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Retirer du panier',
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Quantité
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: () => onQuantityChanged(item.quantity - 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${item.quantity}',
                      style: context.text.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => onQuantityChanged(item.quantity + 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.format(item.totalPrice),
                style: context.text.body1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.palette.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
