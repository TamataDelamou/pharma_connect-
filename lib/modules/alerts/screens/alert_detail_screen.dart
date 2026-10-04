import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../providers/alert_provider.dart';
import '../models/alert.dart';
import '../models/alert_status.dart';
import '../models/alert_severity.dart';
import '../models/alert_type.dart';
import '../../../core/theme/palette.dart';

/// Écran « Détail d'une alerte avec recommandation » (Module 10 — ALR).
///
/// Audit Module 10 (29/08/2026) : cet écran n'existait pas alors qu'il fait
/// partie des trois écrans principaux prévus par le cahier de conception
/// pour ce module — AlertProvider exposait déjà loadAlert()/selectedAlert,
/// mais aucun écran ne les consommait (code mort, jamais un écran routé).
/// AlertCenterScreen naviguait directement vers alert.actionRoute au clic,
/// sans jamais montrer le détail ni la recommandation. Corrigé : le clic
/// ouvre maintenant cet écran, qui propose ensuite l'action métier
/// (actionRoute) en plus de traiter/ignorer l'alerte elle-même.
class AlertDetailScreen extends StatefulWidget {
  final String alertId;

  const AlertDetailScreen({super.key, required this.alertId});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AlertProvider>();
      await provider.loadAlert(widget.alertId);
      if (!mounted) return;
      final alert = provider.selectedAlert;
      if (alert != null && !alert.isRead) {
        await provider.markAsRead(alert.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();
    final alert = provider.selectedAlert;

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
                    onPressed: () {
                      context.read<AlertProvider>().clearSelected();
                      context.pop();
                    },
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Détail de l\'alerte',
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
              child: provider.isLoading || alert == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: _buildContent(context, alert as Alert),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Alert alert) {
    final isCritical = alert.severity == AlertSeverity.critical;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: alert.severityColor
                          .of(context.palette)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        alert.severityIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title, style: context.text.heading3),
                        const SizedBox(height: 4),
                        Text(
                          '${alert.type.icon} ${alert.type.label} · ${alert.timeAgo}',
                          style: context.text.body2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(alert.message, style: context.text.body1),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.palette.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Statut : ${alert.statusLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.palette.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recommandation
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: isCritical
                        ? context.palette.danger
                        : context.palette.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('Recommandation', style: context.text.heading3),
                ],
              ),
              const SizedBox(height: 8),
              Text(alert.recommendation, style: context.text.body2),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Actions
        if (alert.status != AlertStatus.actioned) ...[
          if (alert.actionLabel != null && alert.actionRoute != null)
            PrimaryButton(
              label: alert.actionLabel!,
              onPressed: () => context.push(alert.actionRoute!),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AlertProvider>().markAsActioned(
                      alert.id,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Alerte marquée comme traitée'),
                          backgroundColor: context.palette.success,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Marquer comme traité'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AlertProvider>().dismissAlert(alert.id);
                    if (context.mounted) context.pop();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Ignorer'),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Icon(Icons.check_circle, color: context.palette.success),
              SizedBox(width: 8),
              Text(
                'Cette alerte a déjà été traitée.',
                style: context.text.body2,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
