import 'package:flutter/material.dart';
import '../../../core/widgets/inputs/glass_input.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GlassInput(
      label: '',
      hint: 'Nom du médicament, DCI, classe thérapeutique...',
      controller: _controller,
      prefixIcon: Icons.search,
      suffixIcon: _controller.text.isNotEmpty ? Icons.clear : null,
      onSuffixPressed: () {
        _controller.clear();
        widget.onClear();
        widget.onSearch('');
      },
      onChanged: (value) {
        setState(() {});
        widget.onSearch(value);
      },
    );
  }
}
