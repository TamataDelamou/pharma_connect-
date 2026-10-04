import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/business_company.dart';
import 'package:pharma_connect/core/theme/palette.dart';

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
              color: _typeColor(context, company.type).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                company.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _typeColor(context, company.type),
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
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  company.typeLabel,
                  style: context.text.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (company.city != null)
                  Text(company.city!, style: context.text.micro),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(
                context,
                company.status,
              ).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              company.statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _statusColor(context, company.status),
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
        ],
      ),
    );
  }

  Color _typeColor(BuildContext context, String type) {
    switch (type) {
      case 'hospital':
        return context.palette.danger;
      case 'clinic':
        return context.palette.primary;
      case 'wholesaler':
        return context.palette.secondary;
      case 'laboratory':
        return context.palette.success;
      case 'pharmacy_chain':
        return context.palette.warningStrong;
      case 'insurance':
        return context.palette.warning;
      default:
        return context.palette.textSecondary;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'active':
        return context.palette.success;
      case 'inactive':
        return context.palette.textSecondary;
      case 'pending':
        return context.palette.warning;
      case 'suspended':
        return context.palette.danger;
      case 'archived':
        return context.palette.textSecondary;
      default:
        return context.palette.textSecondary;
    }
  }
}
