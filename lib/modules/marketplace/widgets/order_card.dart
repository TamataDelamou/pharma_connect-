import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../models/b2b_order.dart';
import 'package:pharma_connect/core/theme/palette.dart';

/// Audit Module 13 (B2B, 29/08/2026) : même import mort que `OfferCard`
/// (voir son commentaire) — `OrderCard` n'existait nulle part non plus.
class OrderCard extends StatelessWidget {
  final B2BOrder order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  Color _statusColor(BuildContext context) {
    switch (order.status) {
      case 'draft':
        return context.palette.textSecondary;
      case 'submitted':
        return context.palette.primary;
      case 'confirmed':
        return context.palette.success;
      case 'shipped':
        return context.palette.secondary;
      case 'delivered':
        return context.palette.success;
      case 'cancelled':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
    }
  }

  String _itemsSummary() {
    final items = order.items;
    if (items == null || items.isEmpty) return 'Commande B2B';
    if (items.length == 1) return items.first.productName;
    return '${items.first.productName} +${items.length - 1} autre(s)';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
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
                  _itemsSummary(),
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${order.statusIcon} ${order.statusLabel}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                size: 14,
                color: context.palette.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${order.buyerName ?? 'Acheteur'} → ${order.sellerName ?? 'Vendeur'}',
                  style: context.text.micro,
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
                CurrencyFormatter.format(order.totalAmount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.palette.primary,
                ),
              ),
              Text(
                '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                style: context.text.micro,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
