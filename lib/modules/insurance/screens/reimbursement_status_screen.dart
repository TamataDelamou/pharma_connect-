import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/insurance_provider.dart';
import '../models/reimbursement_tracking.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class ReimbursementStatusScreen extends StatefulWidget {
  final String claimId;

  const ReimbursementStatusScreen({super.key, required this.claimId});

  @override
  State<ReimbursementStatusScreen> createState() =>
      _ReimbursementStatusScreenState();
}

// ASR-4 (audit Module 24, Étape 2/3, 30/08/2026) : cet écran construisait
// auparavant un ReimbursementTracking codé en dur après un simple
// Future.delayed, sans jamais consulter Supabase ni tenir compte de
// widget.claimId (voir le rapport d'audit, §4, constat d'ouverture ASR-4).
// Réécrit pour charger l'état réel via InsuranceProvider.
// loadReimbursementForClaim(), même patron que EnrollmentDetailScreen
// (context.watch<InsuranceProvider>() + chargement en postFrameCallback).
class _ReimbursementStatusScreenState extends State<ReimbursementStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsuranceProvider>().loadReimbursementForClaim(
        widget.claimId,
      );
    });
  }

  void _reload() {
    context.read<InsuranceProvider>().loadReimbursementForClaim(widget.claimId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsuranceProvider>();
    final isLoading = provider.isLoadingReimbursement;
    final error = provider.reimbursementError;
    final tracking = provider.reimbursementTracking;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
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
                      '💰 Suivi du remboursement',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.palette.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(error),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _reload,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : tracking == null
                  ? Center(
                      child: Text(
                        'Aucune information de remboursement disponible',
                        style: context.text.body2,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status timeline
                          _buildStatusTimeline(tracking),
                          const SizedBox(height: 24),

                          // Amounts
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Détails des montants',
                                  style: context.text.heading3,
                                ),
                                const SizedBox(height: 12),
                                _buildAmountRow(
                                  'Montant soumis',
                                  tracking.submittedAmount ?? 0,
                                  context.palette.textSecondary,
                                ),
                                Divider(color: context.palette.veil(0.12)),
                                _buildAmountRow(
                                  'Montant approuvé',
                                  tracking.approvedAmount ?? 0,
                                  context.palette.primary,
                                ),
                                Divider(color: context.palette.veil(0.12)),
                                _buildAmountRow(
                                  'Remboursé',
                                  tracking.reimbursedAmount ?? 0,
                                  context.palette.success,
                                ),
                              ],
                            ),
                          ),

                          if (tracking.status == 'rejected') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.palette.danger.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: context.palette.danger.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: context.palette.danger,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tracking.rejectionReason ??
                                          'Demande rejetée',
                                      style: TextStyle(
                                        color: context.palette.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(ReimbursementTracking tracking) {
    final steps = [
      {'status': 'submitted', 'label': 'Soumis', 'icon': '📤'},
      {'status': 'under_review', 'label': 'En cours d\'examen', 'icon': '🔍'},
      {'status': 'approved', 'label': 'Approuvé', 'icon': '✅'},
      {'status': 'reimbursed', 'label': 'Remboursé', 'icon': '💰'},
    ];

    int currentIndex = steps.indexWhere((s) => s['status'] == tracking.status);
    if (currentIndex == -1) currentIndex = 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('État du remboursement', style: context.text.heading3),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = index < currentIndex;
            final isCurrent = index == currentIndex;

            return Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? context.palette.success
                        : isCurrent
                        ? context.palette.primary
                        : context.palette.veil(0.24),
                  ),
                  child: Center(
                    child: Text(
                      isCompleted ? '✓' : step['icon'] as String,
                      style: TextStyle(
                        fontSize: isCompleted ? 16 : 14,
                        color: isCompleted || isCurrent
                            ? context.palette.textPrimary
                            : context.palette.textSecondary,
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
                        step['label'] as String,
                        style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isCompleted || isCurrent
                              ? context.palette.textPrimary
                              : context.palette.textSecondary,
                        ),
                      ),
                      if (isCurrent && tracking.updatedAt != null)
                        Text(
                          'Mis à jour le ${_formatDate(tracking.updatedAt!)}',
                          style: context.text.micro,
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, int amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: context.text.body2),
          const Spacer(),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
