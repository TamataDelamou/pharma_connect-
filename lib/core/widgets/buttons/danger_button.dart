import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';

class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double width;
  final IconData? icon;

  const DangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width = double.infinity,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width,
      height: 50,
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: PharmaConnectColors.accentRed,
          foregroundColor: PharmaConnectColors.textPrimary,
          disabledBackgroundColor: PharmaConnectColors.accentRed.withValues(
            alpha: 0.3,
          ),
          disabledForegroundColor: PharmaConnectColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      PharmaConnectColors.textPrimary,
                    ),
                  ),
                )
              : Row(
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
      ),
    );
  }
}
