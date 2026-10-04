import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import 'kernel_badge.dart';
import 'kernel_status.dart';
import '../theme/palette.dart';

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
    // C229 : la barre latérale s'anime entre 72 et 260 px ; en dessous de
    // ces seuils, l'en-tête (point, textes, badge) et le détail des services
    // débordaient. Point seul quand la place manque, badge et détail
    // seulement s'ils tiennent.
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 160;
        final showBadge = widget.expanded && constraints.maxWidth >= 240;
        final showDetails = widget.expanded && !compact;
        return _buildIndicator(compact, showBadge, showDetails);
      },
    );
  }

  Widget _buildDot() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.status.isConnected
                ? context.palette.success
                : context.palette.danger,
            boxShadow: widget.status.isConnected
                ? [
                    BoxShadow(
                      color: context.palette.success.withValues(
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
    );
  }

  Widget _buildIndicator(bool compact, bool showBadge, bool showDetails) {
    if (compact) {
      return Tooltip(
        message: widget.status.isConnected
            ? 'GSG Kernel v${widget.status.version}'
            : 'GSG Kernel : non connecté (Dev)',
        child: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: context.palette.cardRaised.copyWith(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          child: _buildDot(),
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(12),
      decoration: context.palette.cardRaised.copyWith(
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ==================== EN-TÊTE ====================
          Row(
            children: [
              // Indicateur de connexion
              _buildDot(),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'GSG KERNEL',
                  style: context.text.subtitle2.copyWith(
                    color: context.palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.status.isConnected
                      ? 'v${widget.status.version}'
                      : 'Non connecté (Dev)',
                  style: context.text.micro.copyWith(
                    color: widget.status.isConnected
                        ? context.palette.textSecondary
                        : context.palette.warning,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (showBadge) ...[const SizedBox(width: 6), const KernelBadge()],
            ],
          ),

          // ==================== DÉTAILS DES SERVICES ====================
          if (showDetails) ...[
            const SizedBox(height: 12),
            Divider(color: context.palette.veil(0.24), height: 1),
            const SizedBox(height: 12),
            // Statistiques
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Services actifs :  ${widget.status.onlineCount}/${widget.status.totalCount}',
                    style: context.text.body2.copyWith(
                      color: context.palette.textSecondary,
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
              style: context.text.micro.copyWith(
                color: context.palette.textFaded(0.7),
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
                    color: context.palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(
                      PharmaConnectSpacing.radiusSm,
                    ),
                    border: Border.all(
                      color: context.palette
                          .resolve(service.statusColor.of(context.palette))
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(service.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          service.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.palette.resolve(
                              service.statusColor.of(context.palette),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.palette.resolve(
                            service.statusColor.of(context.palette),
                          ),
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
