import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/professional_profile.dart';
import '../models/professional_availability.dart';
import '../models/professional_specialty.dart';
import '../models/professional_qualification.dart';

class ProfessionalsService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Profiles ----

  Future<List<ProfessionalProfile>> getProfessionals({
    String? specialty,
    bool? isVerified,
    bool? acceptingNewPatients,
    String? searchQuery,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('professional_profiles')
          .select('*, profiles:profiles(*)');

      if (specialty != null) {
        query = query.eq('specialty', specialty);
      }
      if (isVerified != null) {
        query = query.eq('is_verified', isVerified);
      }
      if (acceptingNewPatients != null) {
        query = query.eq('is_accepting_new_patients', acceptingNewPatients);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.textSearch('profiles.full_name', searchQuery);
      }

      final response = await query.order('profiles(full_name)', ascending: true);
      return (response as List)
          .map((e) => ProfessionalProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load professionals: $e');
    }
  }

  Future<ProfessionalProfile?> getProfessional(String id) async {
    try {
      final response = await _client
          .from('professional_profiles')
          .select('*, profiles:profiles(*)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return ProfessionalProfile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load professional: $e');
    }
  }

  Future<ProfessionalProfile> createProfile(ProfessionalProfile profile) async {
    try {
      final now = DateTime.now().toUtc();
      final data = profile
          .copyWith(
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      // C212 : la vérification (is_verified, verification_status,
      // rejection_reason) est posée par l'administration GSG, jamais envoyée
      // depuis la fiche du professionnel.
      data.removeWhere(
        (key, value) =>
            key == 'full_name' ||
            key == 'phone' ||
            key == 'email' ||
            key == 'profiles' ||
            key == 'is_verified' ||
            key == 'verification_status' ||
            key == 'rejection_reason',
      );

      final response = await _client
          .from('professional_profiles')
          .insert(data)
          .select()
          .single();
      return ProfessionalProfile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create professional profile: $e');
    }
  }

  Future<ProfessionalProfile> updateProfile(ProfessionalProfile profile) async {
    try {
      final data = profile
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      // C212 : la vérification (is_verified, verification_status,
      // rejection_reason) est posée par l'administration GSG, jamais envoyée
      // depuis la fiche du professionnel.
      data.removeWhere(
        (key, value) =>
            key == 'full_name' ||
            key == 'phone' ||
            key == 'email' ||
            key == 'profiles' ||
            key == 'is_verified' ||
            key == 'verification_status' ||
            key == 'rejection_reason',
      );

      final response = await _client
          .from('professional_profiles')
          .update(data)
          .eq('id', profile.id)
          .select()
          .single();
      return ProfessionalProfile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update professional profile: $e');
    }
  }

  Future<void> deleteProfile(String id) async {
    try {
      await _client.from('professional_profiles').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete professional profile: $e');
    }
  }

  // ---- Availability ----

  Future<List<ProfessionalAvailability>> getAvailability(
    String professionalId,
  ) async {
    try {
      final response = await _client
          .from('professional_availability')
          .select()
          .eq('professional_id', professionalId)
          .order('day_of_week', ascending: true);
      return (response as List)
          .map(
            (e) => ProfessionalAvailability.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load availability: $e');
    }
  }

  Future<ProfessionalAvailability> createAvailability(
    ProfessionalAvailability availability,
  ) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = availability
          .copyWith(
            id: newId,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('professional_availability')
          .insert(data)
          .select()
          .single();
      return ProfessionalAvailability.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to create availability: $e');
    }
  }

  Future<ProfessionalAvailability> updateAvailability(
    ProfessionalAvailability availability,
  ) async {
    try {
      final data = availability
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('professional_availability')
          .update(data)
          .eq('id', availability.id)
          .select()
          .single();
      return ProfessionalAvailability.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to update availability: $e');
    }
  }

  Future<void> deleteAvailability(String id) async {
    try {
      await _client.from('professional_availability').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete availability: $e');
    }
  }

  // ---- Specialties (for Referential Engine integration) ----

  Future<List<ProfessionalSpecialty>> getSpecialties({String? category}) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('specialties').select().eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((e) => ProfessionalSpecialty.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load specialties: $e');
    }
  }

  // ---- Qualifications ----

  Future<List<ProfessionalQualification>> getQualifications({
    String? issuingBody,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('qualifications').select().eq('is_active', true);

      if (issuingBody != null) {
        query = query.eq('issuing_body', issuingBody);
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map(
            (e) =>
                ProfessionalQualification.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load qualifications: $e');
    }
  }
}
