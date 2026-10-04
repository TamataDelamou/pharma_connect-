import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/health_record.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class HealthRecordCard extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback onTap;

  const HealthRecordCard({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_information,
                color: context.palette.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dossier médical',
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${record.allergies.length} allergies • ${record.medicalConditions.length} antécédents',
                style: context.text.micro,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (record.bloodType != null)
                _buildChip(
                  'Groupe ${record.bloodType}',
                  context.palette.secondary,
                ),
              if (record.height != null)
                _buildChip('${record.height} cm', context.palette.primary),
              if (record.weight != null)
                _buildChip('${record.weight} kg', context.palette.success),
              if (record.medications.isNotEmpty)
                _buildChip(
                  '${record.medications.length} traitements',
                  context.palette.warning,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mis à jour : ${_formatDate(record.updatedAt)}',
            style: context.text.micro.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return 'il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes}m';
    return 'à l\'instant';
  }
}
