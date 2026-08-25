import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/glass.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class GlassModal extends StatelessWidget {
  final Widget child;
  final double width;
  final double maxWidth;
  final bool dismissible;
  final VoidCallback? onDismiss;
  final String? title;
  final List<Widget>? actions;

  const GlassModal({
    super.key,
    required this.child,
    this.width = 720,
    this.maxWidth = 0.9,
    this.dismissible = true,
    this.onDismiss,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: width.clamp(0, MediaQuery.of(context).size.width * maxWidth),
        decoration: PharmaConnectGlass.glassPrimary.copyWith(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusXl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== EN-TÊTE ====================
            if (title != null || actions != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                child: Row(
                  children: [
                    if (title != null) ...[
                      Expanded(
                        child: Text(
                          title!,
                          style: PharmaConnectTypography.heading3,
                        ),
                      ),
                    ],
                    if (actions != null) ...[...actions!],
                    if (dismissible) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: PharmaConnectColors.textSecondary,
                          size: 24,
                        ),
                        onPressed:
                            onDismiss ?? () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
            ],
            // ==================== CONTENU ====================
            Flexible(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double width = 720,
    double maxWidth = 0.9,
    bool dismissible = true,
    VoidCallback? onDismiss,
    String? title,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: PharmaConnectColors.overlayDark,
      builder: (context) => GlassModal(
        width: width,
        maxWidth: maxWidth,
        dismissible: dismissible,
        onDismiss: onDismiss,
        title: title,
        actions: actions,
        child: child,
      ),
    );
  }
}
