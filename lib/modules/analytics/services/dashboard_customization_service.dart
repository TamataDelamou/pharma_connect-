import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/dashboard_widget.dart';
import '../models/user_dashboard.dart';
import 'analytics_user_scope.dart';

class DashboardCustomizationService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Widgets Catalog ----

  Future<List<DashboardWidget>> getAvailableWidgets() async {
    try {
      final response = await _client
          .from('dashboard_widgets')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);
      return (response as List)
          .map((e) => DashboardWidget.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ---- Current user scope ----
  //
  // Audit Module 28 (BI), Étape 3 (05/09/2026), BI-7 : détermine si
  // l'utilisateur courant doit se voir servir un tableau de bord "officine"
  // (staff rattaché à une pharmacie), "réseau" (compte GSG admin) ou
  // "personal" (tout le reste) — voir 20260905070000_analytics_module_fixes.sql
  // pour les policies RLS correspondantes qui appliquent réellement cette
  // séparation.
  Future<AnalyticsUserScope> getCurrentUserScope() =>
      AnalyticsUserScope.resolveCurrent();

  // ---- User Dashboards (scope = personal) ----

  Future<List<UserDashboard>> getUserDashboards(String ownerId) async {
    try {
      final response = await _client
          .from('user_dashboards')
          .select()
          .eq('owner_id', ownerId)
          .eq('scope', 'personal')
          .order('is_default', ascending: false);
      return (response as List)
          .map((e) => UserDashboard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<UserDashboard?> getDefaultDashboard(String ownerId) async {
    try {
      final response = await _client
          .from('user_dashboards')
          .select()
          .eq('owner_id', ownerId)
          .eq('scope', 'personal')
          .eq('is_default', true)
          .maybeSingle();
      if (response == null) return null;
      return UserDashboard.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // ---- Officine / réseau dashboards (BI-7 : Tableaux de bord partagés) ----

  /// Tableau de bord partagé entre tout le staff de `pharmacyId`. Il n'y a
  /// qu'un tableau officine par pharmacie (contrairement aux tableaux
  /// personnels, dont un compte peut avoir plusieurs).
  Future<UserDashboard?> getOfficineDashboard(String pharmacyId) async {
    try {
      final response = await _client
          .from('user_dashboards')
          .select()
          .eq('scope', 'officine')
          .eq('pharmacy_id', pharmacyId)
          .maybeSingle();
      if (response == null) return null;
      return UserDashboard.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Tableau de bord partagé entre tous les comptes GSG admin
  /// (is_gsg_admin()). Il n'y en a qu'un pour l'ensemble du réseau.
  Future<UserDashboard?> getReseauDashboard() async {
    try {
      final response = await _client
          .from('user_dashboards')
          .select()
          .eq('scope', 'reseau')
          .maybeSingle();
      if (response == null) return null;
      return UserDashboard.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<UserDashboard> saveDashboard(UserDashboard dashboard) async {
    try {
      final now = DateTime.now().toUtc();
      UserDashboard saved;

      if (dashboard.id.isEmpty || dashboard.id.startsWith('temp_')) {
        final id = _uuid.v4();
        final data = dashboard
            .copyWith(
              id: id,
              createdAt: now,
              updatedAt: now,
              createdBy: SupabaseService().currentUser?.id,
              updatedBy: SupabaseService().currentUser?.id,
            )
            .toJson();
        final response = await _client
            .from('user_dashboards')
            .insert(data)
            .select()
            .single();
        saved = UserDashboard.fromJson(response as Map<String, dynamic>);
      } else {
        final data = dashboard
            .copyWith(
              updatedAt: now,
              updatedBy: SupabaseService().currentUser?.id,
            )
            .toJson();
        final response = await _client
            .from('user_dashboards')
            .update(data)
            .eq('id', dashboard.id)
            .select()
            .single();
        saved = UserDashboard.fromJson(response as Map<String, dynamic>);
      }

      return saved;
    } catch (e) {
      throw Exception('Failed to save dashboard: $e');
    }
  }

  Future<void> deleteDashboard(String id) async {
    try {
      await _client.from('user_dashboards').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete dashboard: $e');
    }
  }

  Future<void> setDefaultDashboard(String id, String ownerId) async {
    try {
      // Reset all personal dashboards for this user (is_default n'a de sens
      // que pour scope = personal, un compte pouvant en avoir plusieurs).
      await _client
          .from('user_dashboards')
          .update({'is_default': false})
          .eq('owner_id', ownerId)
          .eq('scope', 'personal');

      // Set this one as default
      await _client
          .from('user_dashboards')
          .update({'is_default': true})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to set default dashboard: $e');
    }
  }
}
