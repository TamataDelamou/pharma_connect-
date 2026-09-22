import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../models/hospital.dart';

class HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final VoidCallback onTap;
  final bool showSelectButton;

  const HospitalCard({
    super.key,
    required this.hospital,
    required this.onTap,
    this.showSelectButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: showSelectButton ? null : onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hospital.isEmergencyAvailable
                  ? PharmaConnectColors.accentRed.withValues(alpha: 0.15)
                  : PharmaConnectColors.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hospital.isEmergencyAvailable
                  ? Icons.local_hospital
                  : Icons.medical_services,
              color: hospital.isEmergencyAvailable
                  ? PharmaConnectColors.accentRed
                  : PharmaConnectColors.accentCyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hospital.name,
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hospital.isEmergencyAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentRed.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Urgences',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  hospital.typeName ?? 'Établissement de santé',
                  style: PharmaConnectTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${hospital.city ?? ''}${hospital.city != null && hospital.country != null ? ', ' : ''}${hospital.country ?? ''}',
                        style: PharmaConnectTypography.micro,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showSelectButton) ...[
            PrimaryButton(label: 'Choisir', onPressed: onTap, width: 100),
          ] else ...[
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ],
      ),
    );
  }
}
