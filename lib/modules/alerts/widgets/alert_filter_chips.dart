import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../models/alert_severity.dart';
import '../models/alert_status.dart';
import '../../../core/theme/palette.dart';

class AlertFilterChips extends StatefulWidget {
  const AlertFilterChips({super.key});

  @override
  State<AlertFilterChips> createState() => _AlertFilterChipsState();
}

class _AlertFilterChipsState extends State<AlertFilterChips> {
  AlertSeverity? _selectedSeverity;
  AlertStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();

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
              // Par sévérité
              _buildFilterChip('Toutes', _selectedSeverity == null, () {
                setState(() {
                  _selectedSeverity = null;
                });
                provider.loadAlerts();
              }),
              const SizedBox(width: 4),
              for (final severity in AlertSeverity.values) ...[
                _buildFilterChip(
                  severity.label,
                  _selectedSeverity == severity,
                  () {
                    setState(() {
                      _selectedSeverity = severity;
                      _selectedStatus = null;
                    });
                    provider.loadAlerts(severity: severity);
                  },
                ),
                const SizedBox(width: 4),
              ],
              // Par statut
              const SizedBox(width: 16),
              for (final status in AlertStatus.values) ...[
                if (status != AlertStatus.new_) ...[
                  _buildFilterChip(status.label, _selectedStatus == status, () {
                    setState(() {
                      _selectedStatus = status;
                      _selectedSeverity = null;
                    });
                    provider.loadAlerts(status: status);
                  }),
                  const SizedBox(width: 4),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
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
