import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../models/financing_request.dart';

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
              color: _statusColor(request.status),
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
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: PharmaConnectColors.accentCyan,
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
                          request.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        request.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(request.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  request.pharmacyName ?? request.pharmacyId,
                  style: PharmaConnectTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '${request.repaymentPeriodMonths} mois',
                      style: PharmaConnectTypography.micro,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${request.totalRepayments ?? 0} paiements',
                      style: PharmaConnectTypography.micro,
                    ),
                    if (request.paidRepayments != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Payés: ${request.paidRepayments}',
                        style: PharmaConnectTypography.micro.copyWith(
                          color: PharmaConnectColors.accentGreen,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return PharmaConnectColors.accentOrange;
      case 'approved':
        return PharmaConnectColors.accentCyan;
      case 'rejected':
        return PharmaConnectColors.accentRed;
      case 'active':
        return PharmaConnectColors.accentPurple;
      case 'completed':
        return PharmaConnectColors.accentGreen;
      case 'defaulted':
        return PharmaConnectColors.accentRed;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }
}
