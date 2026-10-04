import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_customization_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class DashboardWidgetPicker extends StatelessWidget {
  final Function(String) onWidgetSelected;

  const DashboardWidgetPicker({super.key, required this.onWidgetSelected});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardCustomizationProvider>();

    if (provider.availableWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📦 Ajouter un widget', style: context.text.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.availableWidgets.map((widget) {
              return GestureDetector(
                onTap: () => onWidgetSelected(widget.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: context.palette.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.icon ?? '📊',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
