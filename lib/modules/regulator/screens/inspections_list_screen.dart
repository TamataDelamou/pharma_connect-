import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/inspection_provider.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4 : écran de liste pour
// `regulatory_inspections`, jusqu'ici entièrement orpheline. Accessible au
// staff GSG et aux comptes 'regulateur' (RLS `is_gsg_admin() or
// is_regulator()`, posée en Étape 2) ; tout autre compte voit une liste
// vide (RLS), sans erreur.
class InspectionsListScreen extends StatefulWidget {
  const InspectionsListScreen({super.key});

  @override
  State<InspectionsListScreen> createState() => _InspectionsListScreenState();
}

class _InspectionsListScreenState extends State<InspectionsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspectionProvider>().loadInspections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InspectionProvider>();

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
                    'Inspections réglementaires',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/regulator/inspections/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Planifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentPurple,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(InspectionProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: PharmaConnectColors.accentRed,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                provider.loadInspections();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.inspections.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Aucune inspection', style: PharmaConnectTypography.heading3),
            SizedBox(height: 8),
            Text(
              'Aucune inspection réglementaire planifiée pour le moment',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.inspections.length,
      itemBuilder: (context, index) {
        final inspection = provider.inspections[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () => context.push('/regulator/inspections/${inspection.id}'),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(inspection.status),
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
                              '${inspection.entityTypeLabel} · ${inspection.typeLabel}',
                              style: PharmaConnectTypography.body1.copyWith(
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
                                inspection.status,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              inspection.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _statusColor(inspection.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(inspection.inspectionDate),
                        style: PharmaConnectTypography.micro,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'scheduled':
        return PharmaConnectColors.accentCyan;
      case 'in_progress':
        return PharmaConnectColors.accentAmber;
      case 'completed':
        return PharmaConnectColors.accentGreen;
      case 'cancelled':
        return PharmaConnectColors.accentRed;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
