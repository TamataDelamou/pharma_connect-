import 'package:flutter/material.dart';
import '../models/delivery_driver.dart';
import '../../../core/theme/palette.dart';

class DriverInfoCard extends StatelessWidget {
  final DeliveryDriver driver;

  const DriverInfoCard({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: context.palette.secondary.withValues(alpha: 0.2),
          child: Text(
            driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '👤',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.palette.secondary,
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
                style: context.text.body1.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: context.palette.warning),
                  const SizedBox(width: 2),
                  Text(
                    driver.rating?.toStringAsFixed(1) ?? 'N/A',
                    style: context.text.body2,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.delivery_dining,
                    size: 14,
                    color: context.palette.textSecondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${driver.completedDeliveries} livraisons',
                    style: context.text.micro,
                  ),
                ],
              ),
              if (driver.vehicleType != null) ...[
                Text(
                  '${driver.vehicleType} • ${driver.vehiclePlate ?? ''}',
                  style: context.text.micro,
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
                    color: context.palette.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '❄️ Certifié chaîne du froid',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: context.palette.primary,
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
                ? context.palette.success.withValues(alpha: 0.15)
                : context.palette.danger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            driver.isAvailable ? 'Disponible' : 'Indisponible',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: driver.isAvailable
                  ? context.palette.success
                  : context.palette.danger,
            ),
          ),
        ),
      ],
    );
  }
}
