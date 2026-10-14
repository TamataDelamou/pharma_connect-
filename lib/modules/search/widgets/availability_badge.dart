import 'package:flutter/material.dart';
import '../../../core/theme/palette.dart';

class AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  final int count;

  const AvailabilityBadge({
    super.key,
    required this.isAvailable,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? context.palette.success.withValues(alpha: 0.15)
            : context.palette.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAvailable
              ? context.palette.success.withValues(alpha: 0.3)
              : context.palette.danger.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAvailable
                  ? context.palette.success
                  : context.palette.danger,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable
                ? count > 0
                      ? 'Disponible ($count)'
                      : 'Disponible'
                : 'Rupture',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.palette.onTint(
                isAvailable ? context.palette.success : context.palette.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
