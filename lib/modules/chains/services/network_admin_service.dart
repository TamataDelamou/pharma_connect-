import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/network_admin_role.dart';
import '../models/network_dashboard.dart';
import '../models/network_alert.dart';
import '../../../core/utils/currency_formatter.dart';

class NetworkAdminService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Roles ----

  Future<List<NetworkAdminRole>> getRoles({
    String? userId,
    String? groupId,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('network_admin_roles').select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (groupId != null) {
        query = query.eq('pharmacy_group_id', groupId);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => NetworkAdminRole.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load network roles: $e');
    }
  }

  Future<NetworkAdminRole?> getRole(String id) async {
    try {
      final response = await _client
          .from('network_admin_roles')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return NetworkAdminRole.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load role: $e');
    }
  }

  Future<NetworkAdminRole> createRole(NetworkAdminRole role) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = role
          .copyWith(
            id: id,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('network_admin_roles')
          .insert(data)
          .select()
          .single();
      return NetworkAdminRole.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create role: $e');
    }
  }

  Future<NetworkAdminRole> updateRole(NetworkAdminRole role) async {
    try {
      final data = role
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('network_admin_roles')
          .update(data)
          .eq('id', role.id)
          .select()
          .single();
      return NetworkAdminRole.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      await _client.from('network_admin_roles').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete role: $e');
    }
  }

  // ---- Dashboard ----

  Future<NetworkDashboard?> getDashboard(String groupId) async {
    try {
      final response = await _client
          .from('network_dashboard')
          .select()
          .eq('group_id', groupId)
          .maybeSingle();
      if (response == null) return null;
      return NetworkDashboard.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load network dashboard: $e');
    }
  }

  Future<List<NetworkDashboard>> getAllDashboards() async {
    try {
      final response = await _client
          .from('network_dashboard')
          .select()
          .order('group_name', ascending: true);
      return (response as List)
          .map((e) => NetworkDashboard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load network dashboards: $e');
    }
  }

  // ---- Alerts ----

  Future<List<NetworkAlert>> getAlerts({
    String? groupId,
    String? severity,
    bool? unreadOnly,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('network_alerts').select();

      if (groupId != null) {
        query = query.eq('pharmacy_group_id', groupId);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }
      if (unreadOnly != null && unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => NetworkAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load network alerts: $e');
    }
  }

  Future<NetworkAlert> createAlert(NetworkAlert alert) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = alert
          .copyWith(
            id: id,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('network_alerts')
          .insert(data)
          .select()
          .single();
      return NetworkAlert.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create network alert: $e');
    }
  }

  Future<void> markAlertRead(String id) async {
    try {
      await _client
          .from('network_alerts')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark alert as read: $e');
    }
  }

  Future<void> deleteAlert(String id) async {
    try {
      await _client.from('network_alerts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete alert: $e');
    }
  }

  // ---- Activity Log ----

  Future<List<Map<String, dynamic>>> getActivityLog({
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('network_activity_log').select();

      if (userId != null) {
        query = query.eq('admin_user_id', userId);
      }
      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load activity log: $e');
    }
  }
}
