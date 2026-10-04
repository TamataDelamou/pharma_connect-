import 'package:flutter/material.dart';
import '../models/recall_status.dart';
import '../../../core/theme/palette.dart';

class RecallStatusChip extends StatelessWidget {
  final RecallStatus status;
  final bool compact;

  const RecallStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: status.color.of(context.palette).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: status.color.of(context.palette).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: status.color.of(context.palette),
        ),
      ),
    );
  }
}
