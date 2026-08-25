import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/timeslot.dart';

class TimeslotPicker extends StatelessWidget {
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final ValueChanged<TimeSlot> onSlotSelected;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const TimeslotPicker({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélecteur de date
        Row(
          children: [
            const Text(
              'Choisissez un créneau',
              style: PharmaConnectTypography.heading3,
            ),
            const Spacer(),
            // Navigation date
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                onDateChanged(selectedDate.subtract(const Duration(days: 1)));
              },
            ),
            Text(
              _formatDate(selectedDate),
              style: PharmaConnectTypography.body1,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                onDateChanged(selectedDate.add(const Duration(days: 1)));
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Grille de créneaux
        if (slots.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aucun créneau disponible pour cette date',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ),
        ] else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final isSelected = selectedSlot == slot;

              if (!slot.isAvailable) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Center(
                    child: Text(
                      slot.displayTime,
                      style: PharmaConnectTypography.body2.copyWith(
                        color: PharmaConnectColors.textSecondary.withValues(alpha: 
                          0.5,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => onSlotSelected(slot),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PharmaConnectColors.accentCyan.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? PharmaConnectColors.accentCyan
                          : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slot.displayTime,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? PharmaConnectColors.accentCyan
                              : PharmaConnectColors.textPrimary,
                        ),
                      ),
                      if (slot.estimatedWaitMinutes != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '⏱ ${slot.estimatedWaitMinutes} min',
                          style: const TextStyle(
                            fontSize: 10,
                            color: PharmaConnectColors.textSecondary,
                          ),
                        ),
                      ],
                      if (slot.isPeak && isSelected) ...[
                        const SizedBox(height: 2),
                        const Text(
                          '⚠️ Heure de pointe',
                          style: TextStyle(
                            fontSize: 9,
                            color: PharmaConnectColors.accentOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Aujourd'hui";
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Demain';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
