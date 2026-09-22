import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/inspection_provider.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4.
class InspectionDetailScreen extends StatefulWidget {
  final String inspectionId;

  const InspectionDetailScreen({super.key, required this.inspectionId});

  @override
  State<InspectionDetailScreen> createState() =>
      _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspectionProvider>().loadInspection(widget.inspectionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InspectionProvider>();
    final inspection = provider.selectedInspection;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (inspection == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Inspection introuvable',
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
                    'Détail de l\'inspection',
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
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Entité', inspection.entityTypeLabel),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Identifiant entité',
                            inspection.entityId,
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow('Type', inspection.typeLabel),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Date d\'inspection',
                            _formatDate(inspection.inspectionDate),
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow('Statut', inspection.statusLabel),
                          if (inspection.inspectorName != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Inspecteur',
                              inspection.inspectorName!,
                            ),
                          ],
                          if (inspection.findings != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Constatations', inspection.findings!),
                          ],
                          if (inspection.violations.isNotEmpty) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Manquements',
                              inspection.violations.join(', '),
                            ),
                          ],
                          if (inspection.recommendations != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Recommandations',
                              inspection.recommendations!,
                            ),
                          ],
                          if (inspection.actionTaken != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Action prise',
                              inspection.actionTaken!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (inspection.status != 'completed' &&
                        inspection.status != 'cancelled') ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mettre à jour le statut',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (inspection.status == 'scheduled') ...[
                                  _buildActionChip(
                                    'Démarrer',
                                    'in_progress',
                                    PharmaConnectColors.accentAmber,
                                  ),
                                ],
                                if (inspection.status == 'in_progress') ...[
                                  _buildActionChip(
                                    'Terminer',
                                    'completed',
                                    PharmaConnectColors.accentGreen,
                                  ),
                                ],
                                _buildActionChip(
                                  'Annuler',
                                  'cancelled',
                                  PharmaConnectColors.accentRed,
                                ),
                              ],
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

  Widget _buildActionChip(String label, String status, Color color) {
    return GestureDetector(
      onTap: () async {
        final current = context.read<InspectionProvider>().selectedInspection;
        if (current != null) {
          final updated = current.copyWith(status: status);
          final success = await context
              .read<InspectionProvider>()
              .saveInspection(updated);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Statut mis à jour : $label')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
