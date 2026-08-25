enum SuggestionType { product, category, manufacturer, dci }

class SearchSuggestion {
  final String id;
  final String label;
  final String? subtitle;
  final SuggestionType type;
  final String? query;

  const SearchSuggestion({
    required this.id,
    required this.label,
    this.subtitle,
    required this.type,
    this.query,
  });

  String get icon {
    switch (type) {
      case SuggestionType.product:
        return '💊';
      case SuggestionType.category:
        return '📂';
      case SuggestionType.manufacturer:
        return '🏭';
      case SuggestionType.dci:
        return '🧬';
    }
  }
}
