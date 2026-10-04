import 'package:flutter/material.dart';
import '../models/stock_status.dart';
import '../../../core/theme/palette.dart';

class StockStatusChip extends StatelessWidget {
  final StockStatus status;
  final bool showLabel;

  const StockStatusChip({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.of(context.palette).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: status.color.of(context.palette).withValues(alpha: 0.3),
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
              color: status.color.of(context.palette),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              status.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: status.color.of(context.palette),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
