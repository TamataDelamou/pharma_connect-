import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/stock_transfer.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class TransferCard extends StatelessWidget {
  final StockTransfer transfer;
  final VoidCallback onTap;

  const TransferCard({super.key, required this.transfer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor(context, transfer.status),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${transfer.fromPharmacyName ?? '?'} → ${transfer.toPharmacyName ?? '?'}',
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          context,
                          transfer.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        transfer.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(context, transfer.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${transfer.items?.length ?? 0} articles',
                      style: context.text.micro,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(transfer.transferDate),
                      style: context.text.micro,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return context.palette.warning;
      case 'approved':
        return context.palette.primary;
      case 'in_transit':
        return context.palette.secondary;
      case 'received':
        return context.palette.success;
      case 'cancelled':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
