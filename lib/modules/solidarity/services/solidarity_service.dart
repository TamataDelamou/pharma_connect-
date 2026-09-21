import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/solidarity_program.dart';
import '../models/solidarity_beneficiary.dart';

class SolidarityService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Programs ----

  Future<List<SolidarityProgram>> getPrograms({
    String? type,
    bool? isActive,
    String? pharmacyId,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('solidarity_programs').select(
            '*, pharmacies:pharmacy_id(name), beneficiaries:solidarity_beneficiaries(id)',
          );

      if (type != null) {
        query = query.eq('type', type);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }

      final response = await query.order('start_date', ascending: false);
      return (response as List)
          .map((e) => SolidarityProgram.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load solidarity programs: $e');
    }
  }

  Future<SolidarityProgram?> getProgram(String id) async {
    try {
      final response = await _client
          .from('solidarity_programs')
          .select(
            '*, pharmacies:pharmacy_id(name), beneficiaries:solidarity_beneficiaries(id)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return SolidarityProgram.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load program: $e');
    }
  }

  Future<SolidarityProgram> createProgram(SolidarityProgram program) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = program
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
            key == 'pharmacy_name' ||
            key == 'beneficiaries_count' ||
            key == 'pharmacies' ||
            key == 'beneficiaries',
      );

      final response = await _client
          .from('solidarity_programs')
          .insert(data)
          .select()
          .single();
      return SolidarityProgram.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create program: $e');
    }
  }

  Future<SolidarityProgram> updateProgram(SolidarityProgram program) async {
    try {
      final data = program
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'pharmacy_name' ||
            key == 'beneficiaries_count' ||
            key == 'pharmacies' ||
            key == 'beneficiaries',
      );

      final response = await _client
          .from('solidarity_programs')
          .update(data)
          .eq('id', program.id)
          .select()
          .single();
      return SolidarityProgram.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update program: $e');
    }
  }

  Future<void> deleteProgram(String id) async {
    try {
      await _client.from('solidarity_programs').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete program: $e');
    }
  }

  // ---- Beneficiaries ----

  Future<List<SolidarityBeneficiary>> getBeneficiaries({
    String? patientId,
    String? programId,
    String? status,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('solidarity_beneficiaries').select(
            '*, patients:patient_id(full_name), programs:program_id(name)',
          );

      if (patientId != null) {
        query = query.eq('patient_id', patientId);
      }
      if (programId != null) {
        query = query.eq('program_id', programId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('enrollment_date', ascending: false);
      return (response as List)
          .map((e) => SolidarityBeneficiary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load beneficiaries: $e');
    }
  }

  Future<SolidarityBeneficiary?> getBeneficiary(String id) async {
    try {
      final response = await _client
          .from('solidarity_beneficiaries')
          .select(
            '*, patients:patient_id(full_name), programs:program_id(name)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return SolidarityBeneficiary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load beneficiary: $e');
    }
  }

  Future<SolidarityBeneficiary> createBeneficiary(
    SolidarityBeneficiary beneficiary,
  ) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = beneficiary
          .copyWith(
            id: newId,
            enrollmentDate: now,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'program_name' ||
            key == 'patients' ||
            key == 'programs',
      );

      final response = await _client
          .from('solidarity_beneficiaries')
          .insert(data)
          .select()
          .single();
      return SolidarityBeneficiary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create beneficiary: $e');
    }
  }

  Future<SolidarityBeneficiary> updateBeneficiary(
    SolidarityBeneficiary beneficiary,
  ) async {
    try {
      final data = beneficiary
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'program_name' ||
            key == 'patients' ||
            key == 'programs',
      );

      final response = await _client
          .from('solidarity_beneficiaries')
          .update(data)
          .eq('id', beneficiary.id)
          .select()
          .single();
      return SolidarityBeneficiary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update beneficiary: $e');
    }
  }

  Future<void> deleteBeneficiary(String id) async {
    try {
      await _client.from('solidarity_beneficiaries').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete beneficiary: $e');
    }
  }
}
