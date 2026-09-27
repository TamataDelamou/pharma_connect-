import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/business_provider.dart';
import '../models/business_company.dart';

class CompanyDetailScreen extends StatefulWidget {
  final String companyId;

  const CompanyDetailScreen({super.key, required this.companyId});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessProvider>().loadCompany(widget.companyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final company = provider.selectedCompany;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (company == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Entreprise introuvable',
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    company.name,
                    style: PharmaConnectTypography.heading2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/business/company/edit/${company.id}'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _typeColor(
                                    company.type,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  company.typeLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _typeColor(company.type),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    company.status,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  company.statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _statusColor(company.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (company.legalName != null) ...[
                            _buildInfoRow('Raison sociale', company.legalName!),
                            const Divider(color: Colors.white12),
                          ],
                          if (company.registrationNumber != null) ...[
                            _buildInfoRow(
                              'N° Immatriculation',
                              company.registrationNumber!,
                            ),
                            const Divider(color: Colors.white12),
                          ],
                          if (company.taxId != null) ...[
                            _buildInfoRow('N° Fiscal', company.taxId!),
                            const Divider(color: Colors.white12),
                          ],
                          if (company.address != null) ...[
                            _buildInfoRow('Adresse', company.address!),
                            const Divider(color: Colors.white12),
                          ],
                          if (company.city != null) ...[
                            _buildInfoRow('Ville', company.city!),
                            const Divider(color: Colors.white12),
                          ],
                          if (company.phone != null) ...[
                            _buildInfoRow('Téléphone', company.phone!),
                            const Divider(color: Colors.white12),
                          ],
                          if (company.email != null) ...[
                            _buildInfoRow('Email', company.email!),
                            const Divider(color: Colors.white12),
                          ],
                          if (company.website != null) ...[
                            _buildInfoRow('Site web', company.website!),
                            const Divider(color: Colors.white12),
                          ],
                          if (company.contactPersonName != null) ...[
                            _buildInfoRow(
                              'Contact',
                              company.contactPersonName!,
                            ),
                            if (company.contactPersonPhone != null)
                              Text(company.contactPersonPhone!),
                          ],
                          if (company.notes != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Notes', company.notes!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contracts section
                    if (provider.contracts.isNotEmpty) ...[
                      const Text(
                        '📄 Contrats',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...provider.contracts.take(3).map((contract) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contract.title,
                                      style: PharmaConnectTypography.body2
                                          .copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    Text(
                                      '${contract.typeLabel} • ${contract.statusLabel}',
                                      style: PharmaConnectTypography.micro,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white24,
                                ),
                                onPressed: () {
                                  context.push(
                                    '/business/contract/${contract.id}',
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      SecondaryButton(
                        label: 'Voir tous les contrats',
                        onPressed: () {
                          context.push(
                            '/business/contracts',
                            extra: company.id,
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    SecondaryButton(
                      label: 'Nouveau contrat',
                      icon: Icons.add,
                      onPressed: () {
                        context.push(
                          '/business/contract/new',
                          extra: company.id,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: PharmaConnectTypography.label),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body1)),
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
