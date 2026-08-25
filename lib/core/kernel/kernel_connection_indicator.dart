import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/glass.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'kernel_badge.dart';
import 'kernel_status.dart';

class KernelConnectionIndicator extends StatefulWidget {
  final KernelStatus status;
  final bool expanded;

  const KernelConnectionIndicator({
    super.key,
    required this.status,
    this.expanded = false,
  });

  @override
  State<KernelConnectionIndicator> createState() =>
      _KernelConnectionIndicatorState();
}

class _KernelConnectionIndicatorState extends State<KernelConnectionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(12),
      decoration: PharmaConnectGlass.glassDark.copyWith(
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ==================== EN-TÊTE ====================
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicateur de connexion
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.status.isConnected
                          ? PharmaConnectColors.accentGreen
                          : PharmaConnectColors.accentRed,
                      boxShadow: widget.status.isConnected
                          ? [
                              BoxShadow(
                                color: PharmaConnectColors.accentGreen
                                    .withValues(
                                      alpha: 0.4 + 0.3 * _pulseController.value,
                                    ),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'GSG KERNEL',
                  style: PharmaConnectTypography.subtitle2.copyWith(
                    color: PharmaConnectColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.status.isConnected
                      ? 'v${widget.status.version}'
                      : 'Non connecté (Dev)',
                  style: PharmaConnectTypography.micro.copyWith(
                    color: widget.status.isConnected
                        ? PharmaConnectColors.textSecondary
                        : PharmaConnectColors.accentOrange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.expanded) ...[
                const SizedBox(width: 6),
                const KernelBadge(),
              ],
            ],
          ),

          // ==================== DÉTAILS DES SERVICES ====================
          if (widget.expanded) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            // Statistiques
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Services actifs :  ${widget.status.onlineCount}/${widget.status.totalCount}',
                    style: PharmaConnectTypography.body2.copyWith(
                      color: PharmaConnectColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.status.isConnected
                  ? 'Dernière synchro : ${_formatLastSync(widget.status.lastSync)}'
                  : 'Aucune synchronisation — intégration non branchée',
              style: PharmaConnectTypography.micro.copyWith(
                color: PharmaConnectColors.textSecondary.withValues(
                  alpha: 0.7,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Liste des services
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.status.services.map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(
                      PharmaConnectSpacing.radiusSm,
                    ),
                    border: Border.all(
                      color: service.statusColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(service.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        service.name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: service.statusColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: service.statusColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLastSync(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}
