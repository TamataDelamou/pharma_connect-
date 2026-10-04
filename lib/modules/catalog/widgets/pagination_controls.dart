import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const PaginationControls({
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
              ? context.palette.textPrimary
              : context.palette.textSecondary,
        ),
        ..._buildPageNumbers(context),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages - 1
              ? () => onPageChanged(currentPage + 1)
              : null,
          color: currentPage < totalPages - 1
              ? context.palette.textPrimary
              : context.palette.textSecondary,
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context) {
    final pages = <Widget>[];

    // Afficher les pages autour de la page courante
    int startPage = (currentPage - 2).clamp(0, totalPages - 1);
    int endPage = (currentPage + 2).clamp(0, totalPages - 1);

    if (startPage > 0) {
      pages.add(_buildPageNumber(context, 0));
      if (startPage > 1) {
        pages.add(const Text('…'));
      }
    }

    for (int i = startPage; i <= endPage; i++) {
      pages.add(_buildPageNumber(context, i));
    }

    if (endPage < totalPages - 1) {
      if (endPage < totalPages - 2) {
        pages.add(const Text('…'));
      }
      pages.add(_buildPageNumber(context, totalPages - 1));
    }

    return pages;
  }

  Widget _buildPageNumber(BuildContext context, int page) {
    final isCurrent = page == currentPage;

    return GestureDetector(
      onTap: () => onPageChanged(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent
              ? context.palette.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${page + 1}',
          style: TextStyle(
            color: isCurrent
                ? context.palette.primary
                : context.palette.textSecondary,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
