import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/business_provider.dart';
import '../models/business_company.dart';
import 'package:pharma_connect/core/theme/palette.dart';

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
            style: context.text.body2.copyWith(color: context.palette.danger),
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: context.palette.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    company.name,
                    style: context.text.heading2,
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
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
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
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (company.registrationNumber != null) ...[
                            _buildInfoRow(
                              'N° Immatriculation',
                              company.registrationNumber!,
                            ),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (company.taxId != null) ...[
                            _buildInfoRow('N° Fiscal', company.taxId!),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (company.address != null) ...[
                            _buildInfoRow('Adresse', company.address!),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (company.city != null) ...[
                            _buildInfoRow('Ville', company.city!),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (company.phone != null) ...[
                            _buildInfoRow('Téléphone', company.phone!),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (company.email != null) ...[
                            _buildInfoRow('Email', company.email!),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (company.website != null) ...[
                            _buildInfoRow('Site web', company.website!),
                            Divider(color: context.palette.veil(0.12)),
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
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow('Notes', company.notes!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contracts section
                    if (provider.contracts.isNotEmpty) ...[
                      Text('📄 Contrats', style: context.text.heading3),
                      const SizedBox(height: 8),
                      ...provider.contracts.take(3).map((contract) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: context.palette.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.palette.borderSubtle,
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
                                      style: context.text.body2.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${contract.typeLabel} • ${contract.statusLabel}',
                                      style: context.text.micro,
                                    ),
                                  ],
                                ),
                              ),
                              // C232 : écran absent — ouverture du détail
                              // d'un contrat (/business/contract/:id) masquée.
                            ],
                          ),
                        );
                      }),
                      // C232 : écran absent — « Voir tous les contrats »
                      // (/business/contracts) masqué.
                    ],

                    // C232 : écran absent — « Nouveau contrat »
                    // (/business/contract/new) masqué.
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
          SizedBox(width: 120, child: Text(label, style: context.text.label)),
          Expanded(child: Text(value, style: context.text.body1)),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
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

  Color _statusColor(String status) {
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
