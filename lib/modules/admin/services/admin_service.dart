import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/admin_user.dart';
import '../models/admin_role.dart';
import '../models/admin_permission.dart';
import '../models/admin_pharmacy.dart';
import '../models/pharmacy_status.dart';
import '../models/audit_log.dart';
import '../models/system_config.dart';
import '../models/verification_request.dart';
import '../../../core/services/supabase_service.dart';

class AdminService {
  SupabaseClient get _client => SupabaseService().client;

  // ==================== UTILISATEURS ====================

  Future<List<AdminUser>> getUsers({
    AdminRole? role,
    bool? isActive,
    bool? isVerified,
  }) async {
    var query = _client.from('admin_users').select();
    if (role != null) {
      query = query.eq('role', role.name);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (isVerified != null) {
      query = query.eq('is_verified', isVerified);
    }
    final rows = await query;
    return rows.map((row) => AdminUser.fromJson(row)).toList();
  }

  Future<AdminUser> getUser(String id) async {
    final row = await _client
        .from('admin_users')
        .select()
        .eq('id', id)
        .single();
    return AdminUser.fromJson(row);
  }

  Future<AdminUser> createUser({
    required String userId,
    required String email,
    required String fullName,
    required AdminRole role,
    List<AdminPermission>? permissions,
    String? phone,
    String? createdBy,
    String? notes,
  }) async {
    final user = AdminUser(
      id: const Uuid().v4(),
      userId: userId,
      email: email,
      fullName: fullName,
      phone: phone,
      role: role,
      permissions: permissions ?? _getDefaultPermissions(role),
      isActive: true,
      isVerified: false,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      notes: notes,
    );

    final row = await _client
        .from('admin_users')
        .insert(user.toJson())
        .select()
        .single();
    final created = AdminUser.fromJson(row);

    await logAction(
      userId: createdBy ?? 'system',
      userName: 'System',
      action: 'create_user',
      resource: 'user',
      resourceId: created.id,
    );

    return created;
  }

  List<AdminPermission> _getDefaultPermissions(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return AdminPermission.values;
      case AdminRole.admin:
        return [
          AdminPermission.userRead,
          AdminPermission.userUpdate,
          AdminPermission.userActivate,
          AdminPermission.userDeactivate,
          AdminPermission.pharmacyRead,
          AdminPermission.pharmacyUpdate,
          AdminPermission.licenseView,
          AdminPermission.auditRead,
          AdminPermission.reportView,
        ];
      case AdminRole.pharmacyManager:
        return [
          AdminPermission.pharmacyRead,
          AdminPermission.pharmacyUpdate,
          AdminPermission.userRead,
          AdminPermission.reportView,
        ];
      case AdminRole.regulator:
        return [
          AdminPermission.pharmacyRead,
          AdminPermission.licenseView,
          AdminPermission.licenseVerify,
          AdminPermission.reportView,
          AdminPermission.auditRead,
        ];
      case AdminRole.auditor:
        return [
          AdminPermission.auditRead,
          AdminPermission.auditExport,
          AdminPermission.reportView,
        ];
      case AdminRole.support:
        return [
          AdminPermission.supportView,
          AdminPermission.supportCreate,
          AdminPermission.supportUpdate,
          AdminPermission.userRead,
        ];
      case AdminRole.viewer:
        return [
          AdminPermission.userRead,
          AdminPermission.pharmacyRead,
          AdminPermission.reportView,
        ];
    }
  }

  Future<AdminUser> updateUser(String id, AdminUser updated) async {
    final payload = updated.toJson()..remove('id');
    final row = await _client
        .from('admin_users')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    final result = AdminUser.fromJson(row);

    await logAction(
      userId: updated.createdBy ?? 'system',
      userName: 'System',
      action: 'update_user',
      resource: 'user',
      resourceId: id,
    );

    return result;
  }

  Future<AdminUser> toggleUserActive(String id, bool isActive) async {
    final user = await getUser(id);
    final updated = user.copyWith(isActive: isActive);
    return updateUser(id, updated);
  }

  Future<AdminUser> verifyUser(String id) async {
    final user = await getUser(id);
    final updated = user.copyWith(isVerified: true);
    return updateUser(id, updated);
  }

  // ==================== VÉRIFICATION DES RÔLES (C214) ====================
  // Rôle déclaré ≠ rôle vérifié (D58) : ces validations passent par des RPC
  // réservées à is_gsg_admin(), journalisées côté serveur dans audit_logs.

  /// C214 : comptes à rôle déclaré et leur état de vérification.
  /// [state] : 'pending', 'verified', 'rejected' ou 'all'. Avec [search]
  /// (nom, téléphone ou e-mail), les patients sont inclus, pour attribuer un
  /// rôle institutionnel à un compte existant.
  Future<List<VerificationRequest>> getVerificationRequests({
    String state = 'pending',
    String? search,
  }) async {
    final trimmed = search?.trim();
    final rows =
        await _client.rpc(
              'admin_list_verification_requests',
              params: {
                'p_state': state,
                'p_search': (trimmed == null || trimmed.isEmpty)
                    ? null
                    : trimmed,
              },
            )
            as List<dynamic>;
    return rows
        .map((row) => VerificationRequest.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// C214 : validation ou refus d'un grossiste, livreur ou régulateur.
  /// Un refus (motif obligatoire) ramène le compte au rôle patient.
  Future<void> reviewRole(
    String userId, {
    required bool approve,
    String? reason,
  }) async {
    await _client.rpc(
      'admin_review_role',
      params: {'p_user_id': userId, 'p_approve': approve, 'p_reason': reason},
    );
  }

  /// C214 : vérification ou rejet motivé d'une fiche professionnelle.
  Future<void> verifyProfessional(
    String userId, {
    required bool approve,
    String? reason,
  }) async {
    await _client.rpc(
      'admin_verify_professional',
      params: {'p_user_id': userId, 'p_approve': approve, 'p_reason': reason},
    );
  }

  /// C211 / C214 : attribution d'un rôle (et validation immédiate si
  /// [verified]). Sert à retirer une validation ou à créer un régulateur à
  /// partir d'un compte existant.
  Future<void> setUserRole(
    String userId, {
    required String role,
    required bool verified,
  }) async {
    await _client.rpc(
      'admin_set_user_role',
      params: {'p_user_id': userId, 'p_role': role, 'p_verified': verified},
    );
  }

  /// Message lisible d'une erreur renvoyée par les RPC d'administration
  /// (préfixe technique « PROFIL: » retiré).
  static String describeError(Object error) {
    final raw = error is PostgrestException ? error.message : error.toString();
    return raw.replaceFirst(RegExp(r'^PROFIL:\s*'), '');
  }

  // ==================== PHARMACIES ====================
  // AdminPharmacy est une vue partielle de la table canonique
  // public.pharmacies (voir supabase/migrations/20260827000400_pharmacies.sql)
  // partagée avec les modules search/stock.

  Future<List<AdminPharmacy>> getPharmacies({
    PharmacyStatus? status,
    String? groupId,
    bool? isActive,
  }) async {
    var query = _client.from('pharmacies').select();
    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (groupId != null) {
      query = query.eq('group_id', groupId);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    final rows = await query;
    return rows.map((row) => AdminPharmacy.fromJson(row)).toList();
  }

  Future<AdminPharmacy> getPharmacy(String id) async {
    final row = await _client.from('pharmacies').select().eq('id', id).single();
    return AdminPharmacy.fromJson(row);
  }

  Future<AdminPharmacy> createPharmacy({
    required String name,
    required String address,
    required String phone,
    required String email,
    String? licenseNumber,
    String? managerId,
    String? managerName,
    required double latitude,
    required double longitude,
    String? groupId,
    String? groupName,
    String? notes,
  }) async {
    final pharmacy = AdminPharmacy(
      id: const Uuid().v4(),
      name: name,
      address: address,
      phone: phone,
      email: email,
      licenseNumber: licenseNumber,
      status: PharmacyStatus.pending,
      managerId: managerId,
      managerName: managerName,
      latitude: latitude,
      longitude: longitude,
      groupId: groupId,
      groupName: groupName,
      isActive: true,
      createdAt: DateTime.now(),
      notes: notes,
    );

    final row = await _client
        .from('pharmacies')
        .insert(pharmacy.toJson())
        .select()
        .single();
    final created = AdminPharmacy.fromJson(row);

    await logAction(
      userId: 'system',
      userName: 'System',
      action: 'create_pharmacy',
      resource: 'pharmacy',
      resourceId: created.id,
    );

    return created;
  }

  Future<AdminPharmacy> updatePharmacy(String id, AdminPharmacy updated) async {
    final payload = updated.copyWith(statusUpdatedAt: DateTime.now()).toJson()
      ..remove('id');
    final row = await _client
        .from('pharmacies')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    final result = AdminPharmacy.fromJson(row);

    await logAction(
      userId: 'system',
      userName: 'System',
      action: 'update_pharmacy',
      resource: 'pharmacy',
      resourceId: id,
    );

    return result;
  }

  Future<AdminPharmacy> updatePharmacyStatus(
    String id,
    PharmacyStatus status,
  ) async {
    final pharmacy = await getPharmacy(id);
    final updated = pharmacy.copyWith(status: status);
    return updatePharmacy(id, updated);
  }

  Future<AdminPharmacy> verifyPharmacy(String id) async {
    final pharmacy = await getPharmacy(id);
    final updated = pharmacy.copyWith(
      status: PharmacyStatus.verified,
      licenseVerifiedAt: DateTime.now(),
    );
    return updatePharmacy(id, updated);
  }

  Future<AdminPharmacy> approvePharmacy(String id) async {
    final pharmacy = await getPharmacy(id);
    final updated = pharmacy.copyWith(
      status: PharmacyStatus.active,
      licenseVerifiedAt: DateTime.now(),
    );
    return updatePharmacy(id, updated);
  }

  // ==================== AUDIT ====================

  /// C217 : journalisation par la RPC admin_log_action. L'auteur (user_id,
  /// user_name) est fixé par le serveur à partir de la session : [userId] et
  /// [userName] sont conservés pour ne pas changer les appelants, mais ne
  /// sont plus envoyés. Réservé à l'administration GSG ; un échec de
  /// journalisation ne fait pas échouer l'action déjà réalisée.
  Future<void> logAction({
    required String userId,
    required String userName,
    required String action,
    required String resource,
    required String resourceId,
    Map<String, dynamic>? changes,
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    try {
      await _client.rpc(
        'admin_log_action',
        params: {
          'p_action': action,
          'p_resource': resource,
          'p_resource_id': resourceId,
          'p_changes': changes,
          'p_is_success': isSuccess,
          'p_error_message': errorMessage,
        },
      );
    } catch (e) {
      debugPrint('Journal d\'audit non ecrit ($action) : $e');
    }
  }

  Future<List<AuditLog>> getAuditLogs({
    String? userId,
    String? resource,
    String? resourceId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) async {
    var query = _client.from('audit_logs').select();
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    if (resource != null) {
      query = query.eq('resource', resource);
    }
    if (resourceId != null) {
      query = query.eq('resource_id', resourceId);
    }
    if (fromDate != null) {
      query = query.gt('timestamp', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lt('timestamp', toDate.toIso8601String());
    }
    final rows = await query.order('timestamp', ascending: false).limit(limit);
    return rows.map((row) => AuditLog.fromJson(row)).toList();
  }

  // ==================== CONFIGURATION ====================

  Future<List<SystemConfig>> getConfigs({String? category}) async {
    var query = _client.from('system_configs').select();
    if (category != null) {
      query = query.eq('category', category);
    }
    final rows = await query;
    return rows.map((row) => SystemConfig.fromJson(row)).toList();
  }

  Future<SystemConfig> getConfig(String key) async {
    final row = await _client
        .from('system_configs')
        .select()
        .eq('key', key)
        .single();
    return SystemConfig.fromJson(row);
  }

  Future<SystemConfig> updateConfig(
    String key,
    String value,
    String updatedBy,
  ) async {
    final row = await _client
        .from('system_configs')
        .update({
          'value': value,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': updatedBy,
        })
        .eq('key', key)
        .select()
        .single();
    final updated = SystemConfig.fromJson(row);

    await logAction(
      userId: updatedBy,
      userName: updatedBy,
      action: 'update_config',
      resource: 'config',
      resourceId: key,
    );

    return updated;
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getStatistics() async {
    final users = await getUsers();
    final pharmacies = await getPharmacies();
    final auditLogs = await getAuditLogs(limit: 10000);

    return {
      'totalUsers': users.length,
      'activeUsers': users.where((u) => u.isActive).length,
      'verifiedUsers': users.where((u) => u.isVerified).length,
      'totalPharmacies': pharmacies.length,
      'pendingPharmacies': pharmacies
          .where((p) => p.status == PharmacyStatus.pending)
          .length,
      'activePharmacies': pharmacies
          .where((p) => p.status == PharmacyStatus.active)
          .length,
      'totalAuditLogs': auditLogs.length,
      'recentLogs': auditLogs
          .where(
            (l) => l.timestamp.isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            ),
          )
          .length,
    };
  }
}
