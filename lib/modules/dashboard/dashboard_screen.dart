import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/kernel/kernel_badge.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/cards/glass_card.dart';
import '../../core/widgets/navigation/sidebar_navigation.dart';
import '../auth/models/user_role.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/widgets/account_status_banner.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/alert_center.dart';
import 'models/dashboard_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentRoute = '/dashboard';
  bool _sidebarExpanded = true;

  final List<SidebarNavigationItem> _navItems = [
    const SidebarNavigationItem(
      label: 'Tableau de bord',
      icon: Icons.dashboard,
      route: '/dashboard',
    ),
    const SidebarNavigationItem(
      label: 'Recherche',
      icon: Icons.search,
      route: '/search',
    ),
    const SidebarNavigationItem(
      label: 'Catalogue',
      icon: Icons.medication_liquid,
      route: '/catalog',
    ),
    const SidebarNavigationItem(
      label: 'Stock & Lots',
      icon: Icons.inventory,
      route: '/stock',
    ),
    const SidebarNavigationItem(
      label: 'Ordonnances',
      icon: Icons.description,
      route: '/prescriptions',
    ),
    const SidebarNavigationItem(
      label: 'Réservations',
      icon: Icons.shopping_cart,
      route: '/reservations',
    ),
    const SidebarNavigationItem(
      label: 'Livraisons',
      icon: Icons.local_shipping,
      route: '/deliveries',
    ),
    const SidebarNavigationItem(
      label: 'Paramètres',
      icon: Icons.settings,
      route: '/settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchData();
    });
  }

  /// C213 / D64 : menus selon le rôle effectif. Un compte dont le rôle n'est
  /// pas vérifié (ou un patient) n'a pas le menu « Stock & Lots ».
  List<SidebarNavigationItem> _navItemsFor(UserRole? role) {
    if (role != UserRole.patient) return _navItems;
    return _navItems.where((item) => item.route != '/stock').toList();
  }

  /// C213 / D64 : actions rapides selon le rôle effectif. Patient (ou rôle
  /// non vérifié) : recherche, ordonnances, réservations. Caisse et personnel
  /// (C201 / C209) : pharmacien d'une officine active seulement.
  List<QuickAction> _actionsFor(UserRole? role, List<QuickAction> all) {
    if (role == UserRole.patient) {
      const patientRoutes = {'/search', '/prescriptions', '/reservations'};
      return all.where((a) => patientRoutes.contains(a.route)).toList();
    }
    if (role != UserRole.pharmacien) {
      return all
          .where((a) => a.route != '/pos' && a.route != '/pharmacy/staff')
          .toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final role = context.watch<AuthProvider>().effectiveRole;

    return Scaffold(
      body: Row(
        children: [
          SidebarNavigation(
            items: _navItemsFor(role),
            currentRoute: _currentRoute,
            expanded: _sidebarExpanded,
            onItemSelected: (route) {
              setState(() => _currentRoute = route);
              context.go(route);
            },
            onToggleExpand: () {
              setState(() => _sidebarExpanded = !_sidebarExpanded);
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: dashboard.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tableau de bord',
                                    style: PharmaConnectTypography.heading1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Bienvenue sur PharmaConnect — Infrastructure numérique du circuit pharmaceutique',
                                    style: PharmaConnectTypography.body2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const KernelBadge(),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              backgroundColor: PharmaConnectColors.accentCyan
                                  .withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.person,
                                color: PharmaConnectColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // C213 / D64 : état du compte (rôle en attente de
                        // vérification, pharmacien sans officine, etc.).
                        const AccountStatusBanner(),

                        // ===== ACTIONS RAPIDES =====
                        QuickActionGrid(
                          actions: _actionsFor(role, dashboard.data.actions),
                        ),
                        const SizedBox(height: 32),

                        // ===== INDICATEURS CLÉS (3 cartes stats) =====
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.2,
                          children: dashboard.data.stats.map((stat) {
                            return _buildStatCard(stat);
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // ===== ACTIVITÉ RÉCENTE + ALERTES (2 colonnes) =====
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: ActivityTimeline(
                                  activities: dashboard.data.activities,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: AlertCenter(
                                  alerts: dashboard.data.alerts,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(StatCardData stat) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(stat.icon, color: stat.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stat.title,
                  style: PharmaConnectTypography.body2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  stat.value,
                  style: PharmaConnectTypography.kpiMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stat.change,
                  style: PharmaConnectTypography.body2.copyWith(
                    color: stat.color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
