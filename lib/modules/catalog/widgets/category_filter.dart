import 'package:flutter/material.dart';
import '../models/category.dart';
import '../../../core/theme/palette.dart';

class CategoryFilter extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final VoidCallback onClear;

  const CategoryFilter({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégories',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Bouton "Tout"
              _buildChip(
                context,
                label: 'Tout',
                selected: selectedCategoryId == null,
                onSelected: (_) => onClear(),
              ),
              const SizedBox(width: 8),
              ...categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChip(
                    context,
                    label: '${category.icon} ${category.name}',
                    selected: category.id == selectedCategoryId,
                    onSelected: (_) => onCategorySelected(category.id),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: context.palette.primary.withValues(alpha: 0.2),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected ? context.palette.primary : context.palette.veil(0.24),
      ),
      labelStyle: TextStyle(
        color: selected
            ? context.palette.primary
            : context.palette.textSecondary,
        fontSize: 13,
      ),
    );
  }
}
