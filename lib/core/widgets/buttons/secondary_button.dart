import 'package:flutter/material.dart';

import '../../theme/spacing.dart';
import '../../theme/palette.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final double width;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isDisabled = false,
    this.width = double.infinity,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && onPressed != null;

    return SizedBox(
      width: width,
      height: 50,
      child: OutlinedButton(
        onPressed: isInteractive ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isDisabled
              ? context.palette.textSecondary
              : context.palette.textPrimary,
          side: BorderSide(
            color: isDisabled
                ? context.palette.textSecondary.withValues(alpha: 0.2)
                : context.palette.textPrimary.withValues(alpha: 0.2),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
