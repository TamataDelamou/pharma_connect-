import 'package:flutter/material.dart';

import '../../theme/palette.dart';

class TertiaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final IconData? icon;

  const TertiaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isDisabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && onPressed != null;

    return TextButton(
      onPressed: isInteractive ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: isDisabled
            ? context.palette.textSecondary
            : context.palette.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
