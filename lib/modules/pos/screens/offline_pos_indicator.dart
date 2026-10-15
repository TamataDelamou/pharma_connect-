import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offline_pos_provider.dart';
import '../../../core/theme/palette.dart';

class OfflinePOSIndicator extends StatelessWidget {
  const OfflinePOSIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OfflinePOSProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: provider.isOffline
            ? context.palette.warning.withValues(alpha: 0.15)
            : context.palette.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: provider.isOffline
              ? context.palette.warning.withValues(alpha: 0.3)
              : context.palette.success.withValues(alpha: 0.3),
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
                  ? context.palette.warning
                  : context.palette.success,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            provider.isOffline ? '📴 Hors-ligne' : '🟢 En ligne',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: provider.isOffline
                  ? context.palette.warning
                  : context.palette.success,
            ),
          ),
          if (provider.pendingSales > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.palette.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${provider.pendingSales} en attente',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.palette.onTint(context.palette.danger),
                ),
              ),
            ),
          ],
          if (provider.isSyncing) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.palette.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
