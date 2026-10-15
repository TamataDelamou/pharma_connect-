import 'button_label.dart';
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

    // C272 : hauteur minimale, plus fixe : libellé sur deux lignes au plus.
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 50),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          // C272 : hauteur exacte pour un libellé sur une ligne (sans la marge
          // de 48 px du doigt, qui agrandissait les boutons plus bas).
          minimumSize: const Size(0, 50),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 10),
            ],
            // C253 : libellé souple, comme PrimaryButton. Sans cela, un bouton
            // plus étroit que son libellé débordait.
            // C268, C272 : deux lignes au plus, jamais « … » ; rétrécit
            // seulement si deux lignes ne suffisent pas.
            Flexible(
              child: ButtonLabel(
                label,
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
    );
  }
}
