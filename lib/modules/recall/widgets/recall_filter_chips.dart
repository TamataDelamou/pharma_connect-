import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recall_provider.dart';
import '../models/recall_status.dart';
import '../models/recall_severity.dart';
import '../../../core/theme/palette.dart';

class RecallFilterChips extends StatefulWidget {
  const RecallFilterChips({super.key});

  @override
  State<RecallFilterChips> createState() => _RecallFilterChipsState();
}

class _RecallFilterChipsState extends State<RecallFilterChips> {
  RecallStatus? _selectedStatus;
  RecallSeverity? _selectedSeverity;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecallProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtres',
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
              // Par statut
              _buildFilterChip(
                'Tous',
                _selectedStatus == null && _selectedSeverity == null,
                () {
                  setState(() {
                    _selectedStatus = null;
                    _selectedSeverity = null;
                  });
                  provider.loadRecalls();
                },
              ),
              const SizedBox(width: 4),
              for (final status in RecallStatus.values) ...[
                _buildFilterChip(status.label, _selectedStatus == status, () {
                  setState(() {
                    _selectedStatus = status;
                    _selectedSeverity = null;
                  });
                  provider.loadRecalls(status: status);
                }),
                const SizedBox(width: 4),
              ],
              // Par sévérité
              const SizedBox(width: 16),
              for (final severity in RecallSeverity.values) ...[
                _buildFilterChip(
                  severity.label.split(' ')[0],
                  _selectedSeverity == severity,
                  () {
                    setState(() {
                      _selectedSeverity = severity;
                      _selectedStatus = null;
                    });
                    provider.loadRecalls(severity: severity);
                  },
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: context.palette.primary.withValues(alpha: 0.2),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected ? context.palette.primary : context.palette.veil(0.24),
      ),
      labelStyle: TextStyle(
        color: selected
            ? context.palette.primary
            : context.palette.textSecondary,
        fontSize: 12,
      ),
    );
  }
}
