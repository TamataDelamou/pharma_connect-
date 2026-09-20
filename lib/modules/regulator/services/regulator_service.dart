import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/adverse_reaction.dart';
import '../models/adverse_reaction_anonymized.dart';
import '../models/regulatory_inspection.dart';
import '../models/marketing_authorization.dart';

class RegulatorService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Adverse Reactions ----

  Future<List<AdverseReaction>> getAdverseReactions({
    String? patientId,
    String? reporterId,
    String? status,
    String? severity,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('adverse_reactions').select(
            '*, patients:patient_id(full_name), reporters:reporter_id(full_name), products:medication_id(generic_name)',
          );

      if (patientId != null) {
        query = query.eq('patient_id', patientId);
      }
      if (reporterId != null) {
        query = query.eq('reporter_id', reporterId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query.order('reported_at', ascending: false);
      return (response as List)
          .map((e) => AdverseReaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load adverse reactions: $e');
    }
  }

  Future<AdverseReaction?> getAdverseReaction(String id) async {
    try {
      final response = await _client
          .from('adverse_reactions')
          .select(
            '*, patients:patient_id(full_name), reporters:reporter_id(full_name), products:medication_id(generic_name)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return AdverseReaction.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load adverse reaction: $e');
    }
  }

  Future<AdverseReaction> createAdverseReaction(
    AdverseReaction reaction,
  ) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = reaction
          .copyWith(
            id: newId,
            reportedAt: now,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'reporter_name' ||
            key == 'medication_generic_name' ||
            key == 'patients' ||
            key == 'reporters' ||
            key == 'products',
      );

      final response = await _client
          .from('adverse_reactions')
          .insert(data)
          .select()
          .single();
      return AdverseReaction.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create adverse reaction report: $e');
    }
  }

  Future<AdverseReaction> updateAdverseReaction(
    AdverseReaction reaction,
  ) async {
    try {
      final data = reaction
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'reporter_name' ||
            key == 'medication_generic_name' ||
            key == 'patients' ||
            key == 'reporters' ||
            key == 'products',
      );

      final response = await _client
          .from('adverse_reactions')
          .update(data)
          .eq('id', reaction.id)
          .select()
          .single();
      return AdverseReaction.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update adverse reaction: $e');
    }
  }

  Future<void> deleteAdverseReaction(String id) async {
    try {
      await _client.from('adverse_reactions').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete adverse reaction: $e');
    }
  }

  // ---- Adverse Reactions — vue anonymisée (REG-5 / RG-REG-02) ----
  //
  // Audit Module 27 (REG), Étape 3 (05/09/2026) : seule méthode que l'UI
  // doit utiliser pour un compte de rôle 'regulateur' — jamais
  // getAdverseReactions()/getAdverseReaction() ci-dessus, qui exposent la
  // table brute (nominative) et sont désormais réservées au staff GSG
  // (is_gsg_admin()) par la policy RLS posée en Étape 2.
  Future<List<AdverseReactionAnonymized>> getAdverseReactionsAnonymized({
    String? status,
    String? severity,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('adverse_reactions_anonymized').select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map(
            (e) => AdverseReactionAnonymized.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load anonymized adverse reactions: $e');
    }
  }

  // ---- Regulatory Inspections (REG-4) ----

  Future<List<RegulatoryInspection>> getInspections({
    String? entityType,
    String? status,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('regulatory_inspections')
          .select('*, inspectors:inspector_id(full_name)');

      if (entityType != null) {
        query = query.eq('entity_type', entityType);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('inspection_date', ascending: false);
      return (response as List)
          .map((e) => RegulatoryInspection.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load regulatory inspections: $e');
    }
  }

  Future<RegulatoryInspection?> getInspection(String id) async {
    try {
      final response = await _client
          .from('regulatory_inspections')
          .select('*, inspectors:inspector_id(full_name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return RegulatoryInspection.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load regulatory inspection: $e');
    }
  }

  Future<RegulatoryInspection> createInspection(
    RegulatoryInspection inspection,
  ) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = inspection
          .copyWith(
            id: newId,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.remove('inspectors');

      final response = await _client
          .from('regulatory_inspections')
          .insert(data)
          .select()
          .single();
      return RegulatoryInspection.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create regulatory inspection: $e');
    }
  }

  Future<RegulatoryInspection> updateInspection(
    RegulatoryInspection inspection,
  ) async {
    try {
      final data = inspection
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.remove('inspectors');

      final response = await _client
          .from('regulatory_inspections')
          .update(data)
          .eq('id', inspection.id)
          .select()
          .single();
      return RegulatoryInspection.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update regulatory inspection: $e');
    }
  }

  Future<void> deleteInspection(String id) async {
    try {
      await _client.from('regulatory_inspections').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete regulatory inspection: $e');
    }
  }

  // ---- Marketing Authorizations / AMM (REG-4) ----

  Future<List<MarketingAuthorization>> getAuthorizations({
    String? status,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('marketing_authorizations').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map(
            (e) => MarketingAuthorization.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load marketing authorizations: $e');
    }
  }

  Future<MarketingAuthorization?> getAuthorization(String id) async {
    try {
      final response = await _client
          .from('marketing_authorizations')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return MarketingAuthorization.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load marketing authorization: $e');
    }
  }

  Future<MarketingAuthorization> createAuthorization(
    MarketingAuthorization authorization,
  ) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = authorization
          .copyWith(
            id: newId,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();

      final response = await _client
          .from('marketing_authorizations')
          .insert(data)
          .select()
          .single();
      return MarketingAuthorization.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create marketing authorization: $e');
    }
  }

  Future<MarketingAuthorization> updateAuthorization(
    MarketingAuthorization authorization,
  ) async {
    try {
      final data = authorization
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();

      final response = await _client
          .from('marketing_authorizations')
          .update(data)
          .eq('id', authorization.id)
          .select()
          .single();
      return MarketingAuthorization.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update marketing authorization: $e');
    }
  }

  Future<void> deleteAuthorization(String id) async {
    try {
      await _client.from('marketing_authorizations').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete marketing authorization: $e');
    }
  }
}
