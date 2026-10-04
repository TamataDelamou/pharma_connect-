import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../../../core/theme/palette.dart';

class FilterChipsWidget extends StatelessWidget {
  const FilterChipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(
          context,
          label: 'Disponible',
          selected: provider.showOnlyAvailable,
          onSelected: (_) => provider.toggleFilterAvailable(),
        ),
        _buildChip(
          context,
          label: 'Générique',
          selected: provider.showOnlyGeneric,
          onSelected: (_) => provider.toggleFilterGeneric(),
        ),
        _buildChip(
          context,
          label: 'Proche',
          selected: provider.showOnlyNearby,
          onSelected: (_) => provider.toggleFilterNearby(),
        ),
        if (provider.showOnlyAvailable ||
            provider.showOnlyGeneric ||
            provider.showOnlyNearby)
          _buildClearChip(context),
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
    );
  }

  Widget _buildClearChip(BuildContext context) {
    return ActionChip(
      label: const Text('Effacer'),
      onPressed: () {
        context.read<SearchProvider>().clearFilters();
      },
      backgroundColor: Colors.transparent,
      side: BorderSide(color: context.palette.veil(0.24)),
    );
  }
}
