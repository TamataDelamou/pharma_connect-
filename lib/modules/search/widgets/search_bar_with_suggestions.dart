import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../models/search_suggestion.dart';

class SearchBarWithSuggestions extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSearch;
  final Function(SearchSuggestion) onSuggestionSelected;
  final VoidCallback onClear;
  final bool showSuggestions;
  final List<SearchSuggestion> suggestions;
  final List<String> searchHistory;
  final Function(String) onHistoryItemSelected;
  final VoidCallback onClearHistory;

  const SearchBarWithSuggestions({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    required this.onSuggestionSelected,
    required this.onClear,
    required this.showSuggestions,
    required this.suggestions,
    required this.searchHistory,
    required this.onHistoryItemSelected,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassInput(
          label: '',
          hint: 'Médicament, DCI, fabricant...',
          controller: controller,
          prefixIcon: Icons.search,
          suffixIcon: controller.text.isNotEmpty ? Icons.clear : null,
          onSuffixPressed: onClear,
          onChanged: (value) {
            if (value.isNotEmpty) {
              onSearch(value);
            }
          },
        ),
        if (showSuggestions && suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                ...suggestions.map(
                  (suggestion) => ListTile(
                    dense: true,
                    leading: Text(
                      suggestion.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(
                      suggestion.label,
                      style: PharmaConnectTypography.body1,
                    ),
                    subtitle: suggestion.subtitle != null
                        ? Text(
                            suggestion.subtitle!,
                            style: PharmaConnectTypography.micro,
                          )
                        : null,
                    onTap: () => onSuggestionSelected(suggestion),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!showSuggestions &&
            controller.text.isEmpty &&
            searchHistory.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Text('📋 Récentes', style: PharmaConnectTypography.label),
                const Spacer(),
                TextButton(
                  onPressed: onClearHistory,
                  child: const Text(
                    'Effacer',
                    style: TextStyle(
                      color: PharmaConnectColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...searchHistory
              .take(5)
              .map(
                (term) => ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.history,
                    size: 16,
                    color: PharmaConnectColors.textSecondary,
                  ),
                  title: Text(term, style: PharmaConnectTypography.body2),
                  onTap: () => onHistoryItemSelected(term),
                ),
              ),
        ],
      ],
    );
  }
}
