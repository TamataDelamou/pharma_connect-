import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/family_link.dart';
import '../models/family_link_status.dart';
import '../models/family_alert.dart';
import '../models/family_alert_type.dart';

class FamilyService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Family Links ----

  Future<List<FamilyLink>> getLinksForUser(
    String userId, {
    bool asPatient = true,
  }) async {
    try {
      final field = asPatient ? 'patient_id' : 'family_member_id';
      final response = await _client
          .from('family_links')
          .select(
            '*, patients:patient_id(full_name, phone), family_members:family_member_id(full_name, phone)',
          )
          .eq(field, userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => FamilyLink.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load family links: $e');
    }
  }

  Future<FamilyLink?> getLink(String id) async {
    try {
      final response = await _client
          .from('family_links')
          .select(
            '*, patients:patient_id(full_name, phone), family_members:family_member_id(full_name, phone)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return FamilyLink.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load family link: $e');
    }
  }

  Future<FamilyLink> createLink(FamilyLink link) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = link
          .copyWith(
            id: newId,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
            invitedAt: now,
            status: FamilyLinkStatus.pending,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'patient_phone' ||
            key == 'family_member_name' ||
            key == 'family_member_phone',
      );

      final response = await _client
          .from('family_links')
          .insert(data)
          .select()
          .single();
      return FamilyLink.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create family link: $e');
    }
  }

  Future<FamilyLink> updateLink(FamilyLink link) async {
    try {
      final data = link
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'patient_phone' ||
            key == 'family_member_name' ||
            key == 'family_member_phone',
      );

      final response = await _client
          .from('family_links')
          .update(data)
          .eq('id', link.id)
          .select()
          .single();
      return FamilyLink.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update family link: $e');
    }
  }

  Future<FamilyLink> updateLinkStatus(
    String id,
    FamilyLinkStatus newStatus,
  ) async {
    try {
      final data = {
        'status': newStatus.name,
        if (newStatus == FamilyLinkStatus.active)
          'activated_at': DateTime.now().toUtc().toIso8601String(),
        if (newStatus == FamilyLinkStatus.revoked)
          'revoked_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('family_links')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return FamilyLink.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update link status: $e');
    }
  }

  Future<void> deleteLink(String id) async {
    try {
      await _client.from('family_links').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete family link: $e');
    }
  }

  // ---- Family Alerts ----

  // Audit Module 22 (FAM), Étape 3 (30/08/2026), FAM-5 : le filtre
  // `.eq('family_link_id.family_member_id', userId)` référençait le nom
  // brut de la relation (`family_link_id`) alors que le select l'aliasait
  // `patients` — incohérence de même famille que les embeds PostgREST déjà
  // trouvés invalides ailleurs dans le projet (C48/C60). De plus, sans
  // `!inner`, un filtre sur une ressource embarquée ne restreint QUE le
  // contenu embarqué de chaque ligne, pas les lignes `family_alerts`
  // elles-mêmes renvoyées — seule la RLS (qui restreint déjà correctement
  // aux alertes du proche connecté) empêchait une fuite de données ici,
  // pas ce filtre applicatif. Corrigé avec `!inner` (jointure réellement
  // filtrante) et un alias utilisé de façon cohérente entre le select et
  // le filtre. La profondeur d'imbrication change en conséquence — voir le
  // correctif correspondant dans `FamilyAlert.fromJson`.
  Future<List<FamilyAlert>> getAlertsForUser(String userId) async {
    try {
      final response = await _client
          .from('family_alerts')
          .select(
            '*, family_links!inner(family_member_id, patients:patient_id(full_name))',
          )
          .eq('family_links.family_member_id', userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => FamilyAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load alerts: $e');
    }
  }

  Future<List<FamilyAlert>> getAlertsForLink(String familyLinkId) async {
    try {
      final response = await _client
          .from('family_alerts')
          .select('*')
          .eq('family_link_id', familyLinkId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => FamilyAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load link alerts: $e');
    }
  }

  Future<FamilyAlert> createAlert(FamilyAlert alert) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = alert
          .copyWith(
            id: newId,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere((key, value) => key == 'patient_name');

      final response = await _client
          .from('family_alerts')
          .insert(data)
          .select()
          .single();
      return FamilyAlert.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }

  Future<FamilyAlert> markAlertRead(String id) async {
    try {
      final now = DateTime.now().toUtc();
      final data = {
        'is_read': true,
        'read_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('family_alerts')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return FamilyAlert.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to mark alert read: $e');
    }
  }

  Future<void> deleteAlert(String id) async {
    try {
      await _client.from('family_alerts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete alert: $e');
    }
  }

  // ---- Activity Log ----

  Future<void> logActivity({
    required String familyLinkId,
    required String action,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _client.from('family_activity_log').insert({
        'family_link_id': familyLinkId,
        'action': action,
        'details': details ?? {},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Log silently - don't block user flow for audit
    }
  }
}
