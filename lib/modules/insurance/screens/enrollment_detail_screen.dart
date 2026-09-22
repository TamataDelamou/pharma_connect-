import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/insurance_provider.dart';

class EnrollmentDetailScreen extends StatefulWidget {
  final String enrollmentId;

  const EnrollmentDetailScreen({super.key, required this.enrollmentId});

  @override
  State<EnrollmentDetailScreen> createState() => _EnrollmentDetailScreenState();
}

class _EnrollmentDetailScreenState extends State<EnrollmentDetailScreen> {
  final _amountController = TextEditingController();
  String? _procedureType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsuranceProvider>().loadEnrollment(widget.enrollmentId);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsuranceProvider>();
    final enrollment = provider.selectedEnrollment;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (enrollment == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Contrat introuvable',
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
                const Expanded(
                  child: Text(
                    'Contrat d\'assurance',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status card
                    GlassCard(
                      glow: enrollment.isActive,
                      glowColor: enrollment.isActive
                          ? PharmaConnectColors.accentGreen
                          : PharmaConnectColors.textSecondary,
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: enrollment.isActive
                                  ? PharmaConnectColors.accentGreen
                                  : PharmaConnectColors.textSecondary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  enrollment.planName ?? 'Plan',
                                  style: PharmaConnectTypography.heading3,
                                ),
                                Text(
                                  enrollment.companyName ??
                                      enrollment.companyId ??
                                      '',
                                  style: PharmaConnectTypography.body2,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (enrollment.isActive
                                          ? PharmaConnectColors.accentGreen
                                          : PharmaConnectColors.textSecondary)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              enrollment.statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: enrollment.isActive
                                    ? PharmaConnectColors.accentGreen
                                    : PharmaConnectColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Details
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('N° Police', enrollment.policyNumber),
                          const Divider(color: Colors.white12),
                          if (enrollment.memberNumber != null) ...[
                            _buildInfoRow(
                              'N° Adhérent',
                              enrollment.memberNumber!,
                            ),
                            const Divider(color: Colors.white12),
                          ],
                          _buildInfoRow(
                            'Date de début',
                            _formatDate(enrollment.startDate),
                          ),
                          if (enrollment.endDate != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Date d\'expiration',
                              _formatDate(enrollment.endDate!),
                            ),
                          ],
                          if (enrollment.coveragePercentage != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Taux de couverture',
                              '${enrollment.coveragePercentage}%',
                            ),
                          ],
                          if (enrollment.annualLimit != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Plafond annuel',
                              CurrencyFormatter.format(enrollment.annualLimit!),
                            ),
                          ],
                          if (enrollment.notes != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Notes', enrollment.notes!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Coverage calculator
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Simulation de couverture',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Montant (GNF)',
                              border: OutlineInputBorder(),
                              prefixText: 'GNF ',
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _procedureType,
                            decoration: const InputDecoration(
                              labelText: 'Type de prestation',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'consultation',
                                child: Text('Consultation'),
                              ),
                              DropdownMenuItem(
                                value: 'surgery',
                                child: Text('Chirurgie'),
                              ),
                              DropdownMenuItem(
                                value: 'hospitalization',
                                child: Text('Hospitalisation'),
                              ),
                              DropdownMenuItem(
                                value: 'imaging',
                                child: Text('Imagerie'),
                              ),
                              DropdownMenuItem(
                                value: 'laboratory',
                                child: Text('Laboratoire'),
                              ),
                              DropdownMenuItem(
                                value: 'drugs',
                                child: Text('Médicaments'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _procedureType = value),
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: 'Calculer',
                            onPressed: _calculateCoverage,
                            isLoading: provider.isLoading,
                          ),
                          if (provider.coverageCalculation != null) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Montant total',
                              CurrencyFormatter.format(
                                provider.coverageCalculation!['totalAmount']
                                    as int,
                              ),
                            ),
                            _buildInfoRow(
                              'Couverture',
                              '${provider.coverageCalculation!['coveragePercentage']}%',
                            ),
                            _buildInfoRow(
                              'Prise en charge',
                              CurrencyFormatter.format(
                                provider.coverageCalculation!['coveredAmount']
                                    as int,
                              ),
                            ),
                            _buildInfoRow(
                              'Patient',
                              CurrencyFormatter.format(
                                provider.coverageCalculation!['patientResponsibility']
                                    as int,
                              ),
                            ),
                            if (provider
                                    .coverageCalculation!['remainingLimit'] !=
                                null)
                              _buildInfoRow(
                                'Plafond restant',
                                CurrencyFormatter.format(
                                  provider.coverageCalculation!['remainingLimit']
                                      as int,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, enrollment.id),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PharmaConnectColors.accentRed,
                        side: const BorderSide(
                          color: PharmaConnectColors.accentRed,
                        ),
                      ),
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
            width: 140,
            child: Text(label, style: PharmaConnectTypography.label),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body1)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _calculateCoverage() async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    await context.read<InsuranceProvider>().calculateCoverage(
      enrollmentId: widget.enrollmentId,
      amount: amount,
      procedureType: _procedureType,
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Supprimer'),
        content: const Text('Supprimer ce contrat d\'assurance ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<InsuranceProvider>()
                  .deleteEnrollment(id);
              if (success && context.mounted) context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentRed,
              foregroundColor: PharmaConnectColors.textPrimary,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
