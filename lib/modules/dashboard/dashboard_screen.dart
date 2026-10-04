import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/kernel/kernel_badge.dart';
import '../../core/widgets/cards/glass_card.dart';
import '../../core/widgets/layout/responsive.dart';
import '../auth/models/user_role.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/widgets/account_status_banner.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/alert_center.dart';
import 'models/dashboard_data.dart';
import '../../core/theme/palette.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // C226 : le menu (entrées filtrées par rôle effectif) et la déconnexion
  // sont dans lib/routes/app_menu.dart et lib/routes/app_shell.dart.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchData();
    });
  }

  /// C213 / D64 : actions rapides selon le rôle effectif. Patient (ou rôle
  /// non vérifié) : recherche, ordonnances, réservations. Caisse et personnel
  /// (C201 / C209) : pharmacien d'une officine active seulement.
  List<QuickAction> _actionsFor(UserRole? role, List<QuickAction> all) {
    if (role == UserRole.patient) {
      // C231 : /reservations/history (voir dashboard_provider.dart).
      const patientRoutes = {
        '/search',
        '/prescriptions',
        '/reservations/history',
      };
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
    // C233 : mise en page téléphone (une colonne, marges réduites).
    final compact = isCompactWidth(context);

    // C226 : la barre latérale, le menu et la déconnexion sont fournis par
    // AppShell (lib/routes/app_shell.dart) pour toutes les routes connectées.
    return Scaffold(
      body: SingleChildScrollView(
        padding: screenPadding(context),
        child: dashboard.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tableau de bord',
                              style: context.text.heading1,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Bienvenue sur PharmaConnect — Infrastructure numérique du circuit pharmaceutique',
                              style: context.text.body2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const KernelBadge(),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        backgroundColor: context.palette.primary.withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          Icons.person,
                          color: context.palette.primary,
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
                    crossAxisCount: compact ? 1 : 3,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: compact ? 12 : 24,
                    childAspectRatio: compact ? 2.6 : 1.2,
                    children: dashboard.data.stats.map((stat) {
                      return _buildStatCard(stat);
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // ===== ACTIVITÉ RÉCENTE + ALERTES =====
                  // C233 : 2 colonnes en largeur, empilées sur téléphone.
                  if (compact) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: ActivityTimeline(
                        activities: dashboard.data.activities,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: AlertCenter(alerts: dashboard.data.alerts),
                    ),
                  ] else
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
                            child: AlertCenter(alerts: dashboard.data.alerts),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
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
              Icon(
                stat.icon,
                color: context.palette.resolve(stat.color.of(context.palette)),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stat.title,
                  style: context.text.body2,
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
                  style: context.text.kpiMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stat.change,
                  style: context.text.body2.copyWith(
                    color: context.palette.resolve(
                      stat.color.of(context.palette),
                    ),
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
