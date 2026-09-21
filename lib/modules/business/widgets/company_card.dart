import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/business_company.dart';

class CompanyCard extends StatelessWidget {
  final BusinessCompany company;
  final VoidCallback onTap;

  const CompanyCard({super.key, required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor(company.type).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                company.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _typeColor(company.type),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  company.typeLabel,
                  style: PharmaConnectTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (company.city != null)
                  Text(company.city!, style: PharmaConnectTypography.micro),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(company.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              company.statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _statusColor(company.status),
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'hospital':
        return PharmaConnectColors.accentRed;
      case 'clinic':
        return PharmaConnectColors.accentCyan;
      case 'wholesaler':
        return PharmaConnectColors.accentPurple;
      case 'laboratory':
        return PharmaConnectColors.accentGreen;
      case 'pharmacy_chain':
        return PharmaConnectColors.accentAmber;
      case 'insurance':
        return PharmaConnectColors.accentOrange;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return PharmaConnectColors.accentGreen;
      case 'inactive':
        return PharmaConnectColors.textSecondary;
      case 'pending':
        return PharmaConnectColors.accentOrange;
      case 'suspended':
        return PharmaConnectColors.accentRed;
      case 'archived':
        return PharmaConnectColors.textSecondary;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }
}
