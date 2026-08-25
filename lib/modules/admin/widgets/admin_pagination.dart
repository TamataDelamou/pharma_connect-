import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class AdminPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const AdminPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 0
              ? () => onPageChanged(currentPage - 1)
              : null,
          color: currentPage > 0
              ? PharmaConnectColors.textPrimary
              : PharmaConnectColors.textSecondary,
        ),
        Text(
          'Page ${currentPage + 1} / $totalPages',
          style: const TextStyle(color: PharmaConnectColors.textSecondary),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages - 1
              ? () => onPageChanged(currentPage + 1)
              : null,
          color: currentPage < totalPages - 1
              ? PharmaConnectColors.textPrimary
              : PharmaConnectColors.textSecondary,
        ),
      ],
    );
  }
}
