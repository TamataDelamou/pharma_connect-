import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/reservation_item.dart';

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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
        border: Border.all(
          color: item.isSubstitution
              ? PharmaConnectColors.accentPurple.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PharmaConnectColors.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medication,
              color: PharmaConnectColors.accentCyan,
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
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.dosage} • ${CurrencyFormatter.format(item.pricePerUnit)}',
                  style: PharmaConnectTypography.body2,
                ),
                if (item.isSubstitution) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentPurple.withValues(alpha: 0.15),
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
              ],
            ),
          ),
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
                  style: PharmaConnectTypography.body1.copyWith(
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
          const SizedBox(width: 8),
          // Prix total
          Column(
            children: [
              Text(
                CurrencyFormatter.format(item.totalPrice),
                style: PharmaConnectTypography.body1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: PharmaConnectColors.accentCyan,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
