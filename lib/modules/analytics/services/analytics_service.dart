import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_stats.dart';
import '../models/analytics_dashboard.dart';
import 'analytics_user_scope.dart';

class AnalyticsService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Daily Stats ----
  //
  // Audit Module 28 (BI), Étape 2 (05/09/2026), BI-1 : `daily_stats` est une
  // vue matérialisée sans RLS possible, désormais reprise en lecture à
  // `authenticated` (voir 20260905070000_analytics_module_fixes.sql). Ces
  // méthodes interrogent désormais les remparts prévus pour ce rôle :
  // `get_pharmacy_daily_stats()` (Tableau de bord officine, BI-2) pour le
  // staff d'une officine, `daily_stats_scoped` (réseau entier,
  // is_gsg_admin() uniquement) sinon — la lecture directe de `daily_stats`
  // renvoyait "permission denied" pour absolument tout rôle après ce
  // correctif, patient ou non, tant que ce changement n'était pas fait.

  Future<List<DailyStats>> getDailyStats({int days = 30}) async {
    try {
      final scope = await AnalyticsUserScope.resolveCurrent();
      if (scope.isPharmacyStaff) {
        final response = await _client.rpc(
          'get_pharmacy_daily_stats',
          params: {'target_pharmacy_id': scope.pharmacyId, 'days_back': days},
        );
        return (response as List)
            .map((e) => DailyStats.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // is_gsg_admin() : agrégat réseau. Tout autre rôle (patient, livreur,
      // professionnel hors-officine...) : la vue renvoie 0 ligne, l'écran
      // masque alors le graphique (AnalyticsDashboardScreen._buildCharts).
      final response = await _client
          .from('daily_stats_scoped')
          .select()
          .limit(days)
          .order('stat_date', ascending: false);
      return (response as List)
          .map((e) => DailyStats.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load daily stats: $e');
    }
  }

  Future<DailyStats?> getTodayStats() async {
    try {
      final response = await _client
          .from('daily_stats_scoped')
          .select()
          .eq('stat_date', DateTime.now().toIso8601String().substring(0, 10))
          .maybeSingle();
      if (response == null) return null;
      return DailyStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load today stats: $e');
    }
  }

  // ---- Pharmacy Performance ----

  Future<List<PharmacyPerformance>> getPharmaciesPerformance({
    int limit = 20,
  }) async {
    try {
      // BI-1 : vue scopée (is_gsg_admin() -> tout le réseau,
      // is_pharmacy_staff(id) -> sa propre officine seulement, tout autre
      // rôle -> 0 ligne). Corrige la fuite du CA de chaque officine à tout
      // compte authentifié, y compris patient.
      final response = await _client
          .from('pharmacies_performance_scoped')
          .select()
          .order('total_revenue', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => PharmacyPerformance.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load pharmacies performance: $e');
    }
  }

  // ---- Product Performance ----

  Future<List<ProductPerformance>> getTopProducts({int limit = 20}) async {
    try {
      // BI-1 : réservé au personnel officine (toutes officines) et à
      // is_gsg_admin() — agrégat par produit, non identifiant par officine,
      // mais pas une donnée publique pour autant.
      final response = await _client
          .from('top_products_scoped')
          .select()
          .limit(limit);
      return (response as List)
          .map((e) => ProductPerformance.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load top products: $e');
    }
  }

  // ---- Summary ----

  Future<AnalyticsSummary> getSummary() async {
    try {
      // Get today's stats
      final today = await getTodayStats();

      // Get total counts from aggregates
      final consultations = await _client
          .from('consultations')
          .select('id')
          .eq('status', 'completed')
          .count(CountOption.exact);

      final prescriptions = await _client
          .from('prescriptions')
          .select('id')
          .eq('status', 'dispensed')
          .count(CountOption.exact);

      final reservations = await _client
          .from('reservations')
          .select('id')
          .eq('status', 'picked_up')
          .count(CountOption.exact);

      final deliveries = await _client
          .from('deliveries')
          .select('id')
          .eq('status', 'delivered')
          .count(CountOption.exact);

      final transactions = await _client
          .from('transactions')
          .select('amount')
          .eq('status', 'completed');

      int totalRevenue = 0;
      for (final t in transactions as List) {
        totalRevenue += (t as Map<String, dynamic>)['amount'] as int? ?? 0;
      }

      // Low stock products (stock < 5)
      final lowStock = await _client
          .from('stock_items')
          .select('id')
          .lt('total_quantity', 5)
          .gt('total_quantity', 0);

      // Active alerts
      final alerts = await _client
          .from('alerts')
          .select('id')
          .eq('status', 'active');

      return AnalyticsSummary(
        totalConsultations: consultations.count,
        totalPrescriptions: prescriptions.count,
        totalReservations: reservations.count,
        totalDeliveries: deliveries.count,
        totalRevenue: totalRevenue,
        revenueGrowth: 0, // Would require previous period comparison
        activePharmacies: 0, // From pharmacies_performance
        lowStockProducts: lowStock.length,
        pendingAlerts: alerts.length,
        todayStats: today,
      );
    } catch (e) {
      throw Exception('Failed to load summary: $e');
    }
  }

  // ---- Dashboards ----

  Future<List<AnalyticsDashboard>> getUserDashboards(String userId) async {
    try {
      final response = await _client
          .from('analytics_dashboards')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);
      return (response as List)
          .map((e) => AnalyticsDashboard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load dashboards: $e');
    }
  }

  Future<AnalyticsDashboard> getDefaultDashboard(String userId) async {
    try {
      final response = await _client
          .from('analytics_dashboards')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();
      if (response != null) {
        return AnalyticsDashboard.fromJson(response as Map<String, dynamic>);
      }
      // Create default dashboard if none exists
      return _createDefaultDashboard(userId);
    } catch (e) {
      throw Exception('Failed to load default dashboard: $e');
    }
  }

  Future<AnalyticsDashboard> createDashboard(
    AnalyticsDashboard dashboard,
  ) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = dashboard
          .copyWith(
            id: newId,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('analytics_dashboards')
          .insert(data)
          .select()
          .single();
      return AnalyticsDashboard.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create dashboard: $e');
    }
  }

  Future<AnalyticsDashboard> updateDashboard(
    AnalyticsDashboard dashboard,
  ) async {
    try {
      final data = dashboard
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('analytics_dashboards')
          .update(data)
          .eq('id', dashboard.id)
          .select()
          .single();
      return AnalyticsDashboard.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update dashboard: $e');
    }
  }

  Future<void> deleteDashboard(String id) async {
    try {
      await _client.from('analytics_dashboards').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete dashboard: $e');
    }
  }

  Future<AnalyticsDashboard> _createDefaultDashboard(String userId) async {
    final defaultPanels = [
      const AnalyticsPanel(
        id: 'panel_kpi_1',
        type: 'kpi',
        title: 'Consultations',
        config: {'metric': 'consultations'},
        position: 0,
      ),
      const AnalyticsPanel(
        id: 'panel_kpi_2',
        type: 'kpi',
        title: 'Prescriptions',
        config: {'metric': 'prescriptions'},
        position: 1,
      ),
      const AnalyticsPanel(
        id: 'panel_kpi_3',
        type: 'kpi',
        title: 'Chiffre d\'affaires',
        config: {'metric': 'revenue'},
        position: 2,
      ),
      const AnalyticsPanel(
        id: 'panel_chart_1',
        type: 'chart',
        title: 'Activité quotidienne',
        config: {'type': 'area', 'metric': 'consultations'},
        position: 3,
      ),
    ];

    final dashboard = AnalyticsDashboard(
      id: 'default_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: 'Tableau de bord principal',
      description: 'Vue d\'ensemble de l\'activité',
      panels: defaultPanels,
      isDefault: true,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    return await createDashboard(dashboard);
  }
}
