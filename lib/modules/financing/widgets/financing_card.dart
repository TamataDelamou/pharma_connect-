import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../models/financing_request.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class FinancingCard extends StatelessWidget {
  final FinancingRequest request;
  final VoidCallback onTap;

  const FinancingCard({super.key, required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: _statusColor(context, request.status),
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
                        request.statusIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 4,
                      child: Text(
                        CurrencyFormatter.format(request.amount),
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.palette.primary,
                        ),
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
                          request.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        request.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(context, request.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  request.pharmacyName ?? request.pharmacyId,
                  style: context.text.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '${request.repaymentPeriodMonths} mois',
                      style: context.text.micro,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${request.totalRepayments ?? 0} paiements',
                      style: context.text.micro,
                    ),
                    if (request.paidRepayments != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Payés: ${request.paidRepayments}',
                        style: context.text.micro.copyWith(
                          color: context.palette.success,
                        ),
                      ),
                    ],
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
      case 'rejected':
        return context.palette.danger;
      case 'active':
        return context.palette.secondary;
      case 'completed':
        return context.palette.success;
      case 'defaulted':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
    }
  }
}
