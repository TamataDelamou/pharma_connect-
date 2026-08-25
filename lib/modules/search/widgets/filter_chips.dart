import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../providers/search_provider.dart';

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
          label: 'Disponible',
          selected: provider.showOnlyAvailable,
          onSelected: (_) => provider.toggleFilterAvailable(),
        ),
        _buildChip(
          label: 'Générique',
          selected: provider.showOnlyGeneric,
          onSelected: (_) => provider.toggleFilterGeneric(),
        ),
        _buildChip(
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

  Widget _buildChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: PharmaConnectColors.accentCyan.withValues(alpha: 0.2),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected ? PharmaConnectColors.accentCyan : Colors.white24,
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
      side: const BorderSide(color: Colors.white24),
    );
  }
}
