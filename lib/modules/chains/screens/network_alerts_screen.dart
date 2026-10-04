import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../providers/network_admin_provider.dart';
import '../widgets/network_alert_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

// Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-3 : ce fichier
// n'existait pas alors qu'il était importé et utilisé (`NetworkAlertsScreen`)
// à la route `/network/alerts` de `app_router.dart` — défaut de
// compilation confirmé par listing intégral du dossier `screens/` de ce
// module (7 fichiers à l'ouverture, aucun `network_alerts_screen.dart`),
// bloquant potentiellement la compilation de l'application entière (import
// situé dans le routeur global). Créé en s'appuyant sur les méthodes déjà
// exposées par `NetworkAdminProvider` (`loadAlerts`/`alerts`/`markAlertRead`),
// jusqu'ici sans aucun écran consommateur.
class NetworkAlertsScreen extends StatefulWidget {
  const NetworkAlertsScreen({super.key});

  @override
  State<NetworkAlertsScreen> createState() => _NetworkAlertsScreenState();
}

class _NetworkAlertsScreenState extends State<NetworkAlertsScreen> {
  String? _severityFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetworkAdminProvider>().loadAlerts();
    });
  }

  void _reload() {
    context.read<NetworkAdminProvider>().loadAlerts(severity: _severityFilter);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NetworkAdminProvider>();

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
                      '🚨 Alertes réseau',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(null, 'Toutes'),
                  _filterChip('critical', '🔴 Critique'),
                  _filterChip('high', '🟠 Élevée'),
                  _filterChip('medium', '🟡 Moyenne'),
                  _filterChip('low', '🟢 Basse'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String? value, String label) {
    final selected = _severityFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _severityFilter = value);
          _reload();
        },
      ),
    );
  }

  Widget _buildContent(NetworkAdminProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.palette.danger),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: context.text.body2.copyWith(color: context.palette.danger),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                _reload();
              },
              width: 200,
            ),
          ],
        ),
      );
    }
    if (provider.alerts.isEmpty) {
      return Center(
        child: Text('Aucune alerte réseau', style: context.text.body2),
      );
    }
    return ListView.builder(
      itemCount: provider.alerts.length,
      itemBuilder: (context, index) {
        final alert = provider.alerts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NetworkAlertCard(
            alert: alert,
            onRead: () => provider.markAlertRead(alert.id),
          ),
        );
      },
    );
  }
}
