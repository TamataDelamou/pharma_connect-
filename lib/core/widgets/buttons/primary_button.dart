import 'package:flutter/material.dart';

import '../../theme/spacing.dart';
import '../../theme/palette.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double width;
  final IconData? icon;
  // Phase 4 (module financing) : request_detail_screen.dart appelait
  // PrimaryButton(height: ..., fontSize: ...) pour un petit bouton d'action
  // en ligne (repayment), paramètres jamais exposés par ce widget partagé -
  // défaut de compilation, jamais détecté faute de compilateur exécuté à la
  // clôture du Module 14/FIN. Ajoutés en pass-through (additifs, valeurs
  // par défaut identiques au comportement actuel), aucun changement pour
  // les autres appelants.
  final double height;
  final double fontSize;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width = double.infinity,
    this.icon,
    this.height = 50,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.palette.primary,
          foregroundColor: context.palette.onPrimary,
          disabledBackgroundColor: context.palette.primary.withValues(
            alpha: 0.3,
          ),
          disabledForegroundColor: context.palette.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      context.palette.onPrimary,
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
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
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
