import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// C216 / D61 : choix de l'officine destinataire d'une ordonnance déposée.
/// Seul le personnel de l'officine choisie verra et traitera l'ordonnance.
/// Liste les officines validées (vérifiées ou actives).
class DestinationPharmacyPicker extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const DestinationPharmacyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<DestinationPharmacyPicker> createState() =>
      _DestinationPharmacyPickerState();
}

class _DestinationPharmacyPickerState extends State<DestinationPharmacyPicker> {
  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await SupabaseService().client
          .from('pharmacies')
          .select('id, name, address')
          .inFilter('status', ['verified', 'active'])
          .order('name', ascending: true)
          .limit(200);
      if (!mounted) return;
      setState(() {
        _pharmacies = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les officines.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (_error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _error!,
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
          ),
          TextButton(onPressed: _load, child: const Text('Réessayer')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: widget.value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Officine destinataire',
            prefixIcon: Icon(Icons.local_pharmacy),
            border: OutlineInputBorder(),
          ),
          items: [
            for (final pharmacy in _pharmacies)
              DropdownMenuItem<String>(
                value: pharmacy['id'] as String,
                child: Text(
                  [
                    pharmacy['name'] as String? ?? 'Officine',
                    if ((pharmacy['address'] as String?)?.isNotEmpty ?? false)
                      pharmacy['address'] as String,
                  ].join(' — '),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: widget.onChanged,
        ),
        const SizedBox(height: 4),
        const Text(
          'Seule l\'officine choisie pourra voir et préparer votre ordonnance.',
          style: PharmaConnectTypography.micro,
        ),
      ],
    );
  }
}
