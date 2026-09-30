import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/activity_timeline.dart';
import '../widgets/alert_center.dart';
import '../models/dashboard_data.dart';

class RoleBasedDashboard extends StatelessWidget {
  final DashboardData data;

  const RoleBasedDashboard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.userRole;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête personnalisé
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(role),
                    style: PharmaConnectTypography.heading1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(role),
                    style: PharmaConnectTypography.body2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const KernelBadge(),
            const SizedBox(width: 16),
            CircleAvatar(
              backgroundColor: PharmaConnectColors.accentCyan.withValues(
                alpha: 0.2,
              ),
              child: const Icon(
                Icons.person,
                color: PharmaConnectColors.accentCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Actions rapides selon le rôle
        QuickActionGrid(actions: _getActionsForRole(role, data.actions)),
        const SizedBox(height: 32),

        // KPI selon le rôle
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getKpiCount(role),
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.2,
          children: _getStatsForRole(
            role,
            data.stats,
          ).map(_buildStatCard).toList(),
        ),
        const SizedBox(height: 32),

        // Activité et alertes
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: ActivityTimeline(
                  activities: _getActivitiesForRole(role, data.activities),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: AlertCenter(
                  alerts: _getAlertsForRole(role, data.alerts),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getGreeting(UserRole? role) {
    final hour = DateTime.now().hour;
    String time = hour < 12 ? 'Bonjour' : 'Bonsoir';
    switch (role) {
      case UserRole.patient:
        return '$time, patient';
      case UserRole.pharmacien:
        return '$time, pharmacien';
      case UserRole.grossiste:
        return '$time, grossiste';
      case UserRole.livreur:
        return '$time, livreur';
      case UserRole.professionnel:
        return '$time, professionnel de santé';
      case UserRole.regulateur:
        return '$time, régulateur';
      default:
        return '$time, bienvenue';
    }
  }

  String _getSubtitle(UserRole? role) {
    switch (role) {
      case UserRole.patient:
        return 'Gérez vos ordonnances et réservations';
      case UserRole.pharmacien:
        return 'Gérez votre officine et les stocks';
      case UserRole.grossiste:
        return 'Gérez vos approvisionnements';
      case UserRole.livreur:
        return 'Gérez vos livraisons en cours';
      case UserRole.professionnel:
        return 'Suivez vos patients et prescriptions';
      case UserRole.regulateur:
        return 'Supervisez le circuit pharmaceutique';
      default:
        return 'Infrastructure numérique du circuit pharmaceutique';
    }
  }

  List<QuickAction> _getActionsForRole(UserRole? role, List<QuickAction> all) {
    // Filtrer les actions selon le rôle
    if (role == UserRole.patient) {
      return all
          .where(
            (a) =>
                a.route == '/search' ||
                a.route == '/prescriptions' ||
                a.route == '/reservations',
          )
          .toList();
    }
    if (role == UserRole.pharmacien) {
      return all
          .where(
            (a) =>
                a.route == '/stock' ||
                a.route == '/prescriptions' ||
                a.route == '/reservations' ||
                a.route == '/search' ||
                a.route == '/pos' ||
                a.route == '/pharmacy/staff',
          )
          .toList();
    }
    if (role == UserRole.livreur) {
      return all
          .where(
            (a) =>
                a.route == '/deliveries/tracking' ||
                a.route == '/deliveries/history',
          )
          .toList();
    }
    // C201 / C209 : caisse et personnel réservés aux pharmaciens.
    return all
        .where((a) => a.route != '/pos' && a.route != '/pharmacy/staff')
        .toList();
  }

  int _getKpiCount(UserRole? role) {
    switch (role) {
      case UserRole.pharmacien:
        return 3;
      case UserRole.regulateur:
        return 4;
      default:
        return 3;
    }
  }

  List<StatCardData> _getStatsForRole(UserRole? role, List<StatCardData> all) {
    // Personnaliser les KPI selon le rôle
    if (role == UserRole.patient) {
      return [
        const StatCardData(
          title: 'Ordonnances',
          value: '12',
          change: '+3',
          icon: Icons.description,
          color: PharmaConnectColors.accentCyan,
        ),
        const StatCardData(
          title: 'Réservations',
          value: '5',
          change: '2 en attente',
          icon: Icons.shopping_cart,
          color: PharmaConnectColors.accentGreen,
        ),
        const StatCardData(
          title: 'Traitements',
          value: '3',
          change: '2 actifs',
          icon: Icons.medication,
          color: PharmaConnectColors.accentPurple,
        ),
      ];
    }
    return all;
  }

  List<ActivityItem> _getActivitiesForRole(
    UserRole? role,
    List<ActivityItem> all,
  ) {
    if (role == UserRole.pharmacien) {
      // Simuler des activités spécifiques au pharmacien
      return [
        ActivityItem(
          title: 'Nouvelle ordonnance reçue',
          subtitle: 'Patient : Jean Dupont',
          time: DateTime.now(),
          icon: Icons.description,
          color: PharmaConnectColors.accentCyan,
        ),
        ActivityItem(
          title: 'Stock faible : Paracétamol',
          subtitle: 'Seuil critique atteint',
          time: DateTime.now().subtract(const Duration(minutes: 10)),
          icon: Icons.warning,
          color: PharmaConnectColors.accentOrange,
        ),
        ...all,
      ];
    }
    return all;
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

  List<AlertItem> _getAlertsForRole(UserRole? role, List<AlertItem> all) {
    if (role == UserRole.patient) {
      return [
        AlertItem(
          message: 'Votre ordonnance #1234 est prête',
          severity: AlertSeverity.success,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        AlertItem(
          message: 'Rappel : prenez votre traitement',
          severity: AlertSeverity.info,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
    }
    return all;
  }
}
