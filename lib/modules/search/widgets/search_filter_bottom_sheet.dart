import 'package:flutter/material.dart';
import '../models/search_filters.dart';
import '../../../core/theme/palette.dart';

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
              Expanded(child: Text('Filtres', style: context.text.heading2)),
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
          Divider(color: context.palette.veil(0.24)),
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
          Divider(color: context.palette.veil(0.24)),
          const SizedBox(height: 16),

          // Prix
          Text('Prix', style: context.text.label),
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
          Divider(color: context.palette.veil(0.24)),
          const SizedBox(height: 16),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.palette.veil(0.24)),
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
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
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
      title: Text(label, style: context.text.body1),
      value: value,
      onChanged: onChanged,
      activeColor: context.palette.primary,
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
        labelStyle: context.text.label,
        filled: true,
        fillColor: context.palette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.palette.veil(0.24)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.palette.veil(0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.palette.primary),
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
