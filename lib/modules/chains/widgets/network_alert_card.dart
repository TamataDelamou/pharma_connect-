import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/network_alert.dart';

// Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-2 : ce fichier
// n'existait pas alors qu'il était importé et consommé (classe
// `NetworkAlertCard`) par `network_dashboard_screen.dart` — défaut de
// compilation confirmé par listing intégral du dossier `widgets/` de ce
// module (3 fichiers, aucun `network_alert_card.dart`). Créé en suivant le
// même patron que `TransferCard`/`GroupCard` déjà présents dans ce dossier.
class NetworkAlertCard extends StatelessWidget {
  final NetworkAlert alert;
  final VoidCallback? onRead;
  final VoidCallback? onTap;

  const NetworkAlertCard({
    super.key,
    required this.alert,
    this.onRead,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: alert.severityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: PharmaConnectTypography.body2.copyWith(
                          fontWeight: alert.isRead
                              ? FontWeight.w400
                              : FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: alert.severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.severityLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: alert.severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(alert.typeLabel, style: PharmaConnectTypography.micro),
                    if (alert.description != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          alert.description!,
                          style: PharmaConnectTypography.micro,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!alert.isRead && onRead != null)
            IconButton(
              icon: const Icon(Icons.mark_email_read, size: 18),
              tooltip: 'Marquer comme lue',
              onPressed: onRead,
              color: PharmaConnectColors.accentCyan,
            ),
        ],
      ),
    );
  }
}
