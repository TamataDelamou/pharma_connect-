import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/delivery_driver.dart';

class DriverInfoCard extends StatelessWidget {
  final DeliveryDriver driver;

  const DriverInfoCard({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: PharmaConnectColors.accentPurple.withValues(
            alpha: 0.2,
          ),
          child: Text(
            driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '👤',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: PharmaConnectColors.accentPurple,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.name,
                style: PharmaConnectTypography.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 14,
                    color: PharmaConnectColors.accentOrange,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    driver.rating?.toStringAsFixed(1) ?? 'N/A',
                    style: PharmaConnectTypography.body2,
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.delivery_dining,
                    size: 14,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${driver.completedDeliveries} livraisons',
                    style: PharmaConnectTypography.micro,
                  ),
                ],
              ),
              if (driver.vehicleType != null) ...[
                Text(
                  '${driver.vehicleType} • ${driver.vehiclePlate ?? ''}',
                  style: PharmaConnectTypography.micro,
                ),
              ],
              if (driver.isColdChainCertified) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: PharmaConnectColors.accentCyan.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '❄️ Certifié chaîne du froid',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: PharmaConnectColors.accentCyan,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: driver.isAvailable
                ? PharmaConnectColors.accentGreen.withValues(alpha: 0.15)
                : PharmaConnectColors.accentRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            driver.isAvailable ? 'Disponible' : 'Indisponible',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: driver.isAvailable
                  ? PharmaConnectColors.accentGreen
                  : PharmaConnectColors.accentRed,
            ),
          ),
        ),
      ],
    );
  }
}
