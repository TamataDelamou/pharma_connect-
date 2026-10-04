import 'package:flutter/material.dart';
import 'kernel_ui.dart';

import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../theme/palette.dart';

class KernelBadge extends StatelessWidget {
  final bool showIcon;
  final double size;
  final bool showLabel;

  const KernelBadge({
    super.key,
    this.showIcon = true,
    this.size = 16,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!KernelUi.enabled) return const SizedBox.shrink();

    // C233 : en largeur téléphone, le badge se réduit à son icône. Il est
    // posé dans l'en-tête de la plupart des écrans, à côté du titre, auquel
    // il ne laissait presque plus de place.
    final compact =
        (MediaQuery.maybeSizeOf(context)?.width ?? double.infinity) <
        PharmaConnectTypography.compactBreakpoint;
    final showLabel = this.showLabel && !(compact && showIcon);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusSm),
        border: Border.all(
          color: context.palette.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.palette.secondary.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Text('⚡', style: TextStyle(fontSize: size)),
            if (showLabel) const SizedBox(width: 4),
          ],
          if (showLabel) ...[
            Text(
              'Kernel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.palette.secondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
