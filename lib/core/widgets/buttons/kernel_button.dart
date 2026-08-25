import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';

class KernelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double width;

  const KernelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width,
      height: 50,
      child: OutlinedButton(
        onPressed: isInteractive ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: PharmaConnectColors.accentPurple.withValues(
            alpha: 0.10,
          ),
          foregroundColor: isDisabled
              ? PharmaConnectColors.textSecondary
              : PharmaConnectColors.accentPurple,
          side: BorderSide(
            color: isDisabled
                ? PharmaConnectColors.textSecondary.withValues(alpha: 0.2)
                : PharmaConnectColors.accentPurple.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
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
                      PharmaConnectColors.accentPurple,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
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
