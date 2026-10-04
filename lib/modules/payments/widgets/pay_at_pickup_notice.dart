import 'package:flutter/material.dart';
import '../../../core/pilot/pilot_config.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/spacing.dart';

/// C239 : encart affiché à la place du choix du moyen de paiement tant
/// qu'aucun paiement en ligne n'est activé (`PilotConfig`).
class PayAtPickupNotice extends StatelessWidget {
  const PayAtPickupNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
        border: Border.all(color: context.palette.primary, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storefront, color: context.palette.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PilotConfig.payAtPickupLabel,
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aucun paiement en ligne : vous réglez votre commande à '
                  'l\'officine, au moment du retrait.',
                  style: context.text.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
