import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/health_record.dart';

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
              const Icon(
                Icons.medical_information,
                color: PharmaConnectColors.accentCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dossier médical',
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${record.allergies.length} allergies • ${record.medicalConditions.length} antécédents',
                style: PharmaConnectTypography.micro,
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
                  PharmaConnectColors.accentPurple,
                ),
              if (record.height != null)
                _buildChip(
                  '${record.height} cm',
                  PharmaConnectColors.accentCyan,
                ),
              if (record.weight != null)
                _buildChip(
                  '${record.weight} kg',
                  PharmaConnectColors.accentGreen,
                ),
              if (record.medications.isNotEmpty)
                _buildChip(
                  '${record.medications.length} traitements',
                  PharmaConnectColors.accentOrange,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mis à jour : ${_formatDate(record.updatedAt)}',
            style: PharmaConnectTypography.micro.copyWith(
              color: PharmaConnectColors.textSecondary,
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
