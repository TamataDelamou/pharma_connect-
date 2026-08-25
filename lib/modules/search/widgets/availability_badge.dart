import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

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
            ? PharmaConnectColors.accentGreen.withValues(alpha: 0.15)
            : PharmaConnectColors.accentRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAvailable
              ? PharmaConnectColors.accentGreen.withValues(alpha: 0.3)
              : PharmaConnectColors.accentRed.withValues(alpha: 0.3),
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
                  ? PharmaConnectColors.accentGreen
                  : PharmaConnectColors.accentRed,
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
              color: isAvailable
                  ? PharmaConnectColors.accentGreen
                  : PharmaConnectColors.accentRed,
            ),
          ),
        ],
      ),
    );
  }
}
