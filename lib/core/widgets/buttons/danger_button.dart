import 'package:flutter/material.dart';

import '../../theme/spacing.dart';
import '../../theme/palette.dart';

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

    // C272 : hauteur minimale, plus fixe : libellé sur deux lignes au plus.
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 50),
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.palette.danger,
          foregroundColor: context.palette.onDanger,
          disabledBackgroundColor: context.palette.danger.withValues(
            alpha: 0.3,
          ),
          disabledForegroundColor: context.palette.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          // C272 : hauteur exacte pour un libellé sur une ligne (sans la marge
          // de 48 px du doigt, qui agrandissait les boutons plus bas).
          minimumSize: const Size(0, 50),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.palette.textPrimary,
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
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
