import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../providers/search_provider.dart';
import '../widgets/search_bar_with_suggestions.dart';
import '../widgets/search_filter_bottom_sheet.dart';
import '../widgets/search_result_card.dart';
import '../widgets/search_skeleton.dart';
import '../widgets/search_empty_state.dart';
import '../widgets/search_error_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SearchProvider>();
      provider.loadHistory();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recherche',
                    style: PharmaConnectTypography.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Trouvez vos médicaments en un instant',
                    style: PharmaConnectTypography.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                // Bouton scan code-barres
                IconButton(
                  onPressed: () => _showScanner(context),
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: PharmaConnectColors.accentCyan,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton filtres
                Badge(
                  label: Text('${provider.filterCount}'),
                  isLabelVisible: provider.hasFilters,
                  child: IconButton(
                    onPressed: () => _showFilterBottomSheet(context),
                    icon: const Icon(
                      Icons.filter_list,
                      color: PharmaConnectColors.textSecondary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barre de recherche avec suggestions
            SearchBarWithSuggestions(
              controller: _controller,
              focusNode: _focusNode,
              onSearch: (query) => provider.search(query: query),
              onSuggestionSelected: (suggestion) =>
                  provider.selectSuggestion(suggestion),
              onClear: () {
                _controller.clear();
                provider.clearSearch();
              },
              showSuggestions: provider.showSuggestions,
              suggestions: provider.suggestions,
              searchHistory: provider.searchHistory,
              onHistoryItemSelected: (query) {
                _controller.text = query;
                provider.search(query: query);
              },
              onClearHistory: () => provider.clearHistory(),
            ),
            const SizedBox(height: 16),

            // Filtres actifs
            if (provider.hasFilters) ...[
              _buildActiveFilters(provider),
              const SizedBox(height: 12),
            ],

            // Résultats ou état
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SearchProvider provider) {
    switch (provider.status) {
      case SearchStatus.idle:
        return SearchEmptyState(
          title: 'Que recherchez-vous ?',
          subtitle: 'Médicament, DCI, fabricant, catégorie...',
          icon: Icons.search,
          hasHistory: provider.searchHistory.isNotEmpty,
          history: provider.searchHistory,
          onHistoryTap: (query) {
            _controller.text = query;
            provider.search(query: query);
          },
        );

      case SearchStatus.searching:
        return const SearchSkeleton();

      case SearchStatus.error:
        return SearchErrorState(
          message: provider.error ?? 'Une erreur est survenue',
          onRetry: () => provider.search(query: _controller.text),
        );

      case SearchStatus.loaded:
        if (provider.results.isEmpty) {
          return SearchEmptyState(
            title: 'Aucun résultat',
            subtitle: 'Essayez avec d\'autres mots-clés ou filtres',
            icon: Icons.search_off,
          );
        }

        return ListView.builder(
          itemCount: provider.results.length,
          itemBuilder: (context, index) {
            final result = provider.results[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SearchResultCard(
                result: result,
                onTap: () => context.push('/product/${result.product.id}'),
                showAvailability: true,
              ),
            );
          },
        );
    }
  }

  Widget _buildActiveFilters(SearchProvider provider) {
    final filters = provider.filters;
    final chips = <Widget>[];

    if (filters.category != null) {
      chips.add(
        _buildFilterChip('Cat: ${filters.category}', () {
          provider.updateFilters(filters.copyWith(category: null));
        }),
      );
    }

    if (filters.manufacturer != null) {
      chips.add(
        _buildFilterChip('Fab: ${filters.manufacturer}', () {
          provider.updateFilters(filters.copyWith(manufacturer: null));
        }),
      );
    }

    if (filters.onlyAvailable == true) {
      chips.add(
        _buildFilterChip('Disponible', () {
          provider.updateFilters(filters.copyWith(onlyAvailable: null));
        }),
      );
    }

    if (filters.onlyGeneric == true) {
      chips.add(
        _buildFilterChip('Générique', () {
          provider.updateFilters(filters.copyWith(onlyGeneric: null));
        }),
      );
    }

    if (filters.onlyPrescriptionRequired == true) {
      chips.add(
        _buildFilterChip('Sur ordonnance', () {
          provider.updateFilters(
            filters.copyWith(onlyPrescriptionRequired: null),
          );
        }),
      );
    }

    if (filters.minPrice != null || filters.maxPrice != null) {
      chips.add(
        _buildFilterChip(
          'Prix: ${filters.minPrice ?? 0} - ${filters.maxPrice ?? "∞"}',
          () {
            provider.updateFilters(
              filters.copyWith(minPrice: null, maxPrice: null),
            );
          },
        ),
      );
    }

    chips.add(
      _buildFilterChip('Effacer tout', provider.clearFilters, isClear: true),
    );

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildFilterChip(
    String label,
    VoidCallback onDelete, {
    bool isClear = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isClear
            ? PharmaConnectColors.accentRed.withValues(alpha: 0.1)
            : PharmaConnectColors.accentCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClear
              ? PharmaConnectColors.accentRed.withValues(alpha: 0.3)
              : PharmaConnectColors.accentCyan.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onDelete,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isClear
                      ? PharmaConnectColors.accentRed
                      : PharmaConnectColors.accentCyan,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 14,
                color: isClear
                    ? PharmaConnectColors.accentRed
                    : PharmaConnectColors.accentCyan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PharmaConnectColors.primaryDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SearchFilterBottomSheet(
        filters: context.read<SearchProvider>().filters,
        onApply: (newFilters) {
          context.read<SearchProvider>().updateFilters(newFilters);
        },
        onClear: () {
          context.read<SearchProvider>().clearFilters();
        },
      ),
    );
  }

  void _showScanner(BuildContext context) {
    // Navigation vers l'écran de scan (à implémenter)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '📷 Scanner de code-barres (à implémenter avec mobile_scanner)',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
