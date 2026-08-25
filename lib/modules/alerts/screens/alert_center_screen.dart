import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../providers/alert_provider.dart';
import '../widgets/alert_card.dart';
import '../widgets/alert_filter_chips.dart';
import '../models/alert_type.dart';
import '../models/alert_severity.dart';

class AlertCenterScreen extends StatefulWidget {
  const AlertCenterScreen({super.key});

  @override
  State<AlertCenterScreen> createState() => _AlertCenterScreenState();
}

class _AlertCenterScreenState extends State<AlertCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertProvider>().loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Centre d\'alertes',
                        style: PharmaConnectTypography.heading2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.unreadCount} notifications non lues',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                if (provider.unreadCount > 0) ...[
                  TextButton.icon(
                    onPressed: () async {
                      await provider.markAllAsRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Toutes les alertes ont été marquées comme lues',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Tout lire'),
                    style: TextButton.styleFrom(
                      foregroundColor: PharmaConnectColors.accentCyan,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Filtres
            const AlertFilterChips(),
            const SizedBox(height: 16),

            // Liste
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.alerts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune alerte',
                            style: PharmaConnectTypography.heading2,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Vous êtes à jour !',
                            style: PharmaConnectTypography.body2,
                          ),
                        ],
                      ),
                    )
                  : _buildGroupedAlerts(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedAlerts(AlertProvider provider) {
    // Regrouper les alertes par type
    final Map<AlertType, List> grouped = {};
    for (final alert in provider.alerts) {
      grouped[alert.type] ??= [];
      grouped[alert.type]!.add(alert);
    }

    // Définir l'ordre des types (priorité)
    final priorityOrder = [
      AlertType.stockCritical,
      AlertType.stockOut,
      AlertType.recall,
      AlertType.counterfeit,
      AlertType.expirySoon,
      AlertType.expired,
      AlertType.deliveryArrived,
      AlertType.reservationReady,
      AlertType.paymentSuccess,
      AlertType.prescriptionValidated,
    ];

    final sortedTypes = priorityOrder
        .where((t) => grouped.containsKey(t))
        .toList();
    final remainingTypes =
        grouped.keys.where((t) => !priorityOrder.contains(t)).toList()
          ..sort((a, b) => a.label.compareTo(b.label));

    final orderedTypes = [...sortedTypes, ...remainingTypes];

    return ListView.builder(
      itemCount: orderedTypes.length,
      itemBuilder: (context, index) {
        final type = orderedTypes[index];
        final alerts = grouped[type]!;

        final criticalCount = alerts
            .where((a) => a.severity == AlertSeverity.critical)
            .length;
        final warningCount = alerts
            .where((a) => a.severity == AlertSeverity.warning)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${type.icon} ${type.label}',
                    style: PharmaConnectTypography.heading3,
                  ),
                  const SizedBox(width: 8),
                  if (criticalCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: PharmaConnectColors.accentRed.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${criticalCount} urgent${criticalCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: PharmaConnectColors.accentRed,
                        ),
                      ),
                    ),
                  ],
                  if (warningCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: PharmaConnectColors.accentOrange.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${warningCount} avertissement${warningCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: PharmaConnectColors.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AlertCard(
                  alert: alert,
                  onTap: () async {
                    if (!alert.isRead) {
                      await provider.markAsRead(alert.id);
                    }
                    if (alert.actionRoute != null) {
                      context.push(alert.actionRoute!);
                    }
                  },
                  onDismiss: () => provider.dismissAlert(alert.id),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
