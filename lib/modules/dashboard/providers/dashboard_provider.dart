import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../models/dashboard_data.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardData? _data;
  bool _isLoading = false;

  DashboardData get data => _data ?? _getDefaultData();
  bool get isLoading => _isLoading;

  void fetchData() {
    _isLoading = true;
    notifyListeners();

    // Simuler un appel réseau
    Future.delayed(const Duration(milliseconds: 500), () {
      _data = _generateData();
      _isLoading = false;
      notifyListeners();
    });
  }

  DashboardData _generateData() {
    return DashboardData(
      stats: const [
        StatCardData(
          title: 'Pharmacies actives',
          value: '1,284',
          change: '+12%',
          icon: Icons.local_pharmacy,
          color: PharmaConnectColors.accentCyan,
        ),
        StatCardData(
          title: 'Disponibilité des médicaments essentiels',
          value: '94%',
          change: '+3%',
          icon: Icons.check_circle,
          color: PharmaConnectColors.accentGreen,
        ),
        StatCardData(
          title: 'Alertes de stock',
          value: '23',
          change: '⚠️ 5 critiques',
          icon: Icons.notifications_active,
          color: PharmaConnectColors.accentOrange,
        ),
      ],
      actions: const [
        QuickAction(
          label: 'Rechercher',
          icon: Icons.search,
          route: '/search',
          color: PharmaConnectColors.accentCyan,
        ),
        QuickAction(
          label: 'Ordonnance',
          icon: Icons.description,
          route: '/prescriptions',
          color: PharmaConnectColors.accentPurple,
        ),
        // C231 : `/reservations` n'existe pas ; la liste est /reservations/history.
        QuickAction(
          label: 'Réservation',
          icon: Icons.shopping_cart,
          route: '/reservations/history',
          color: PharmaConnectColors.accentGreen,
        ),
        // C231 : action « Stats » retirée, `/stats` n'existe pas.
        // C201 / C209 : vente au comptoir sur le stock réel, personnel de
        // l'officine. Proposées aux pharmaciens uniquement.
        QuickAction(
          label: 'Caisse',
          icon: Icons.point_of_sale,
          route: '/pos',
          color: PharmaConnectColors.accentGreen,
        ),
        QuickAction(
          label: 'Personnel',
          icon: Icons.groups,
          route: '/pharmacy/staff',
          color: PharmaConnectColors.accentCyan,
        ),
      ],
      activities: [
        ActivityItem(
          title: 'Ordonnance #1234 validée',
          subtitle: 'Par Dr. Martin',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          icon: Icons.check_circle,
          color: PharmaConnectColors.accentGreen,
        ),
        ActivityItem(
          title: 'Réservation #5678 retirée',
          subtitle: 'Patient : Jean Dupont',
          time: DateTime.now().subtract(const Duration(minutes: 20)),
          icon: Icons.shopping_cart,
          color: PharmaConnectColors.accentCyan,
        ),
        ActivityItem(
          title: 'Alerte stock faible',
          subtitle: 'Paracétamol 500mg - Rupture imminente',
          time: DateTime.now().subtract(const Duration(hours: 1)),
          icon: Icons.warning,
          color: PharmaConnectColors.accentOrange,
        ),
      ],
      alerts: [
        AlertItem(
          message: 'Rupture imminente : Paracétamol 500mg',
          severity: AlertSeverity.warning,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AlertItem(
          message: '4 lots en péremption dans 30 jours',
          severity: AlertSeverity.warning,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AlertItem(
          message: 'Aucune alerte de contrefaçon détectée',
          severity: AlertSeverity.success,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
    );
  }

  DashboardData _getDefaultData() {
    return _generateData();
  }
}
