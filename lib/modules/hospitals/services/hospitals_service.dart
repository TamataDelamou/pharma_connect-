import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/hospital.dart';
import '../models/hospital_type.dart';

class HospitalsService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Hospitals ----

  Future<List<Hospital>> getHospitals({
    String? typeId,
    String? city,
    bool? isActive,
    bool? hasEmergency,
    String? searchQuery,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('hospitals')
          .select('*, types:type_id(name), departments:departments(id)');

      if (typeId != null) {
        query = query.eq('type_id', typeId);
      }
      if (city != null) {
        query = query.ilike('city', '%$city%');
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (hasEmergency != null && hasEmergency) {
        query = query.eq('is_emergency_available', true);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,'
          'city.ilike.%$searchQuery%,'
          'address.ilike.%$searchQuery%',
        );
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((e) => Hospital.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load hospitals: $e');
    }
  }

  Future<Hospital?> getHospital(String id) async {
    try {
      final response = await _client
          .from('hospitals')
          .select('*, types:type_id(name), departments:departments(id)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Hospital.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load hospital: $e');
    }
  }

  Future<Hospital> createHospital(Hospital hospital) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = hospital
          .copyWith(
            id: newId,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'type_name' ||
            key == 'department_count' ||
            key == 'types' ||
            key == 'departments',
      );

      final response = await _client
          .from('hospitals')
          .insert(data)
          .select()
          .single();
      return Hospital.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create hospital: $e');
    }
  }

  Future<Hospital> updateHospital(Hospital hospital) async {
    try {
      final data = hospital
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'type_name' ||
            key == 'department_count' ||
            key == 'types' ||
            key == 'departments',
      );

      final response = await _client
          .from('hospitals')
          .update(data)
          .eq('id', hospital.id)
          .select()
          .single();
      return Hospital.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update hospital: $e');
    }
  }

  Future<void> deleteHospital(String id) async {
    try {
      await _client.from('hospitals').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete hospital: $e');
    }
  }

  // ---- Hospital Types ----

  Future<List<HospitalType>> getHospitalTypes({String? category}) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('hospital_types').select();

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((e) => HospitalType.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load hospital types: $e');
    }
  }
}
