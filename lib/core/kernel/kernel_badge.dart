import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PharmaConnectColors.accentPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusSm),
        border: Border.all(
          color: PharmaConnectColors.accentPurple.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: PharmaConnectColors.accentPurple.withValues(alpha: 0.15),
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
            const Text(
              'Kernel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: PharmaConnectColors.accentPurple,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
