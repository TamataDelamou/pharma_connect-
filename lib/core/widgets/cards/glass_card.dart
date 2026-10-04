import 'package:flutter/material.dart';

import '../../theme/palette.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final bool glow;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool hoverEffect;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16,
    this.glow = false,
    this.glowColor,
    this.onTap,
    this.hoverEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = onTap != null;
    final palette = context.palette;

    return MouseRegion(
      cursor: isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          transform: hoverEffect && isInteractive
              ? (Matrix4.identity()..translateByDouble(0, -2, 0, 1))
              : Matrix4.identity(),
          decoration: glow
              ? palette.cardGlow(
                  glowColor != null && glowColor! == palette.secondary
                      ? palette.secondary
                      : palette.primary,
                )
              : palette.card,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
