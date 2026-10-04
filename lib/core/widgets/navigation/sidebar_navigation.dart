import 'package:flutter/material.dart';

import '../../kernel/kernel_connection_indicator.dart';
import '../../kernel/kernel_status.dart';
import '../../theme/spacing.dart';
import '../../theme/palette.dart';

class SidebarNavigationItem {
  final String label;
  final IconData icon;
  final String route;
  final bool isActive;

  const SidebarNavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    this.isActive = false,
  });
}

class SidebarNavigation extends StatefulWidget {
  final List<SidebarNavigationItem> items;
  final String currentRoute;
  final ValueChanged<String> onItemSelected;
  final bool expanded;
  final VoidCallback? onToggleExpand;

  /// C231 : affiche « Se déconnecter » en bas de la barre quand il est fourni.
  final VoidCallback? onLogout;

  const SidebarNavigation({
    super.key,
    required this.items,
    required this.currentRoute,
    required this.onItemSelected,
    this.expanded = true,
    this.onToggleExpand,
    this.onLogout,
  });

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: widget.expanded ? 1 : 0,
    );
    _widthAnimation =
        Tween<double>(
          begin: PharmaConnectSpacing.sidebarCollapsed,
          end: PharmaConnectSpacing.sidebarExpanded,
        ).animate(
          CurvedAnimation(parent: _expandController, curve: Curves.easeOut),
        );
  }

  @override
  void didUpdateWidget(SidebarNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: context.palette.cardRaised.copyWith(
            borderRadius: BorderRadius.circular(0),
            boxShadow: [
              BoxShadow(
                color: context.palette.isDark
                    ? context.palette.shadow
                    : context.palette.shadow,
                blurRadius: 20,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // ==================== BRAND ====================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    // C245 : menu déplié, le nom prend toute la place restante
                    // (« PHARM… » à 360 px : il n'en avait que le tiers).
                    Flexible(
                      flex: widget.expanded ? 0 : 1,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '◈',
                          style: TextStyle(
                            fontSize: 28,
                            color: context.palette.primary,
                          ),
                        ),
                      ),
                    ),
                    if (widget.expanded) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PHARMACONNECT',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.palette.textPrimary,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (!widget.expanded) const Spacer(),
                    if (widget.onToggleExpand != null) ...[
                      IconButton(
                        icon: Icon(
                          widget.expanded
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                          color: context.palette.textSecondary,
                          size: 20,
                        ),
                        onPressed: widget.onToggleExpand,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ),

              Divider(color: context.palette.veil(0.12), height: 1),

              // ==================== ITEMS ====================
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isActive = item.route == widget.currentRoute;

                    return _SidebarItem(
                      item: item,
                      isActive: isActive,
                      expanded: widget.expanded,
                      onTap: () => widget.onItemSelected(item.route),
                    );
                  },
                ),
              ),

              // ==================== DÉCONNEXION (C231) ====================
              if (widget.onLogout != null) ...[
                Divider(color: context.palette.veil(0.12), height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _SidebarItem(
                    item: const SidebarNavigationItem(
                      label: 'Se déconnecter',
                      icon: Icons.logout,
                      route: '',
                    ),
                    isActive: false,
                    expanded: widget.expanded,
                    onTap: widget.onLogout!,
                  ),
                ),
              ],

              // ==================== KERNEL INDICATOR ====================
              Padding(
                padding: const EdgeInsets.all(12),
                child: KernelConnectionIndicator(
                  // TODO(kernel-integration) : ce statut est un placeholder de
                  // développement, pas une lecture réelle du GSG Kernel — aucune
                  // intégration réseau n'existe encore (cf. audit KER-ARC-03).
                  // Ne jamais remettre isConnected/online en dur ici : brancher un
                  // KernelStatusPort réel (HTTP + fallback) avant de rétablir un
                  // statut "connecté".
                  status: KernelStatus(
                    isConnected: false,
                    version: '3.0',
                    services: [
                      const KernelService(
                        name: 'GSG ID',
                        icon: '🔐',
                        status: KernelServiceStatus.offline,
                      ),
                      const KernelService(
                        name: 'Org Registry',
                        icon: '🏛️',
                        status: KernelServiceStatus.offline,
                      ),
                      const KernelService(
                        name: 'Referential',
                        icon: '📋',
                        status: KernelServiceStatus.offline,
                      ),
                      const KernelService(
                        name: 'Audit',
                        icon: '📝',
                        status: KernelServiceStatus.offline,
                      ),
                    ],
                    lastSync: DateTime.fromMillisecondsSinceEpoch(0),
                  ),
                  expanded: widget.expanded,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final SidebarNavigationItem item;
  final bool isActive;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isActive
                ? context.palette.primary.withValues(alpha: 0.10)
                : (_isHovered
                      ? context.palette.surfaceMuted
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
            border: widget.isActive
                ? Border(
                    left: BorderSide(color: context.palette.primary, width: 3),
                  )
                : null,
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: context.palette.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // C245 : menu déplié, l'icône garde sa taille et le libellé prend
              // toute la place restante (il n'en avait que la moitié).
              Flexible(
                flex: widget.expanded ? 0 : 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Icon(
                    widget.item.icon,
                    color: widget.isActive
                        ? context.palette.primary
                        : (_isHovered
                              ? context.palette.textPrimary
                              : context.palette.textSecondary),
                    size: 22,
                  ),
                ),
              ),
              if (widget.expanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.isActive
                          ? context.palette.textPrimary
                          : (_isHovered
                                ? context.palette.textPrimary
                                : context.palette.textSecondary),
                    ),
                  ),
                ),
                if (widget.isActive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.palette.primary,
                      boxShadow: [
                        BoxShadow(
                          color: context.palette.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
