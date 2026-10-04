import 'package:flutter/material.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import 'delivery_status_badge.dart';
import '../../../core/theme/palette.dart';

class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback? onTap;
  final bool compact;

  const DeliveryCard({
    super.key,
    required this.delivery,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Expanded(
                child: Text(
                  delivery.patientName,
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DeliveryStatusBadge(status: delivery.status),
            ],
          ),
          const SizedBox(height: 8),
          // Adresse
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: context.palette.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  delivery.deliveryAddress,
                  style: context.text.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Détails
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                delivery.isExpress ? Icons.flash_on : Icons.schedule,
                size: 14,
                color: delivery.isExpress
                    ? context.palette.warning
                    : context.palette.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                delivery.isExpress ? 'Express' : 'Standard',
                style: context.text.micro,
              ),
              const SizedBox(width: 12),
              if (delivery.isColdChainRequired) ...[
                Icon(Icons.ac_unit, size: 14, color: context.palette.primary),
                const SizedBox(width: 4),
                Text(
                  'Chaîne du froid',
                  style: context.text.micro.copyWith(
                    color: context.palette.primary,
                  ),
                ),
              ],
              const Spacer(),
              if (delivery.driver != null) ...[
                Text('👤 ${delivery.driver!.name}', style: context.text.micro),
              ],
            ],
          ),
          if (!compact && delivery.status == DeliveryStatus.inProgress) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.palette.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16, color: context.palette.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⏱ ${delivery.estimatedArrival}',
                      style: context.text.body2.copyWith(
                        color: context.palette.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
