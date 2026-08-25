import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class SearchEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool hasHistory;
  final List<String> history;
  final ValueChanged<String>? onHistoryTap;

  const SearchEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.hasHistory = false,
    this.history = const [],
    this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: PharmaConnectColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: PharmaConnectTypography.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
            if (hasHistory && history.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: history.take(5).map((term) {
                  return ActionChip(
                    label: Text(term),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    onPressed: onHistoryTap == null
                        ? null
                        : () => onHistoryTap!(term),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
