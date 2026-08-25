import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/search_filters.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilters filters;
  final Function(SearchFilters) onApply;
  final VoidCallback onClear;

  const SearchFilterBottomSheet({
    super.key,
    required this.filters,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late SearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.filters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              const Expanded(
                child: Text('Filtres', style: PharmaConnectTypography.heading2),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filters = const SearchFilters();
                  });
                  widget.onClear();
                  Navigator.pop(context);
                },
                child: const Text('Tout effacer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          // Disponibilité
          _buildSwitchTile(
            label: 'Uniquement disponible',
            value: _filters.onlyAvailable ?? false,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(
                  onlyAvailable: value ? true : null,
                );
              });
            },
          ),

          // Générique
          _buildSwitchTile(
            label: 'Uniquement génériques',
            value: _filters.onlyGeneric ?? false,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(onlyGeneric: value ? true : null);
              });
            },
          ),

          // Sur ordonnance
          _buildSwitchTile(
            label: 'Uniquement sur ordonnance',
            value: _filters.onlyPrescriptionRequired ?? false,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(
                  onlyPrescriptionRequired: value ? true : null,
                );
              });
            },
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          // Prix
          const Text('Prix', style: PharmaConnectTypography.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPriceField('Min', _filters.minPrice, (value) {
                  setState(() {
                    _filters = _filters.copyWith(
                      minPrice: value > 0 ? value : null,
                    );
                  });
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceField('Max', _filters.maxPrice, (value) {
                  setState(() {
                    _filters = _filters.copyWith(
                      maxPrice: value > 0 ? value : null,
                    );
                  });
                }),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_filters);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Appliquer les filtres'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(label, style: PharmaConnectTypography.body1),
      value: value,
      onChanged: onChanged,
      activeColor: PharmaConnectColors.accentCyan,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildPriceField(
    String label,
    double? value,
    ValueChanged<double> onChanged,
  ) {
    return TextFormField(
      initialValue: value != null ? value.toString() : '',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: PharmaConnectTypography.label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PharmaConnectColors.accentCyan),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }
}
