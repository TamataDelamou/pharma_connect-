import 'package:flutter/material.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/cold_equipment.dart';
import '../models/equipment_type.dart';
import '../../../core/theme/palette.dart';

class EquipmentCard extends StatelessWidget {
  final ColdEquipment equipment;
  final VoidCallback onTap;

  const EquipmentCard({
    super.key,
    required this.equipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(equipment.type.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.name,
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(equipment.model, style: context.text.body2),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${equipment.currentTemperature.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: equipment.isTemperatureValid
                            ? context.palette.success
                            : context.palette.danger,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${equipment.type.label}',
                      style: context.text.micro,
                    ),
                    if (equipment.location != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '📍 ${equipment.location}',
                        style: context.text.micro,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: equipment.statusColor
                  .of(context.palette)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              equipment.statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: equipment.statusColor.of(context.palette),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
