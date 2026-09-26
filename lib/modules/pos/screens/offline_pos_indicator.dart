import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import '../providers/offline_pos_provider.dart';

class OfflinePOSIndicator extends StatelessWidget {
  const OfflinePOSIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OfflinePOSProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: provider.isOffline
            ? PharmaConnectColors.accentOrange.withValues(alpha: 0.15)
            : PharmaConnectColors.accentGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: provider.isOffline
              ? PharmaConnectColors.accentOrange.withValues(alpha: 0.3)
              : PharmaConnectColors.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: provider.isOffline
                  ? PharmaConnectColors.accentOrange
                  : PharmaConnectColors.accentGreen,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            provider.isOffline ? '📴 Hors-ligne' : '🟢 En ligne',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: provider.isOffline
                  ? PharmaConnectColors.accentOrange
                  : PharmaConnectColors.accentGreen,
            ),
          ),
          if (provider.pendingSales > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: PharmaConnectColors.accentRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${provider.pendingSales} en attente',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: PharmaConnectColors.accentRed,
                ),
              ),
            ),
          ],
          if (provider.isSyncing) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  PharmaConnectColors.accentCyan,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
