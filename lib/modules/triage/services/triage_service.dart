import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/triage_patient.dart';
import '../models/triage_status.dart';
import '../models/triage_assessment.dart';

class TriageService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Patients ----

  Future<List<TriagePatient>> getPatients({
    TriageStatus? status,
    String? nurseId,
    String? patientId,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('triage_patients').select(
            '*, patients:patient_id(full_name, phone), nurses:triage_nurse_id(full_name), doctors:assigned_doctor_id(full_name)',
          );

      if (status != null) {
        query = query.eq('status', status.name);
      }
      if (nurseId != null) {
        query = query.eq('triage_nurse_id', nurseId);
      }
      if (patientId != null) {
        query = query.eq('patient_id', patientId);
      }

      final response = await query
          .order('priority_level', ascending: true)
          .order('arrival_time', ascending: true);
      return (response as List)
          .map((e) => TriagePatient.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load triage patients: $e');
    }
  }

  Future<TriagePatient?> getPatient(String id) async {
    try {
      final response = await _client
          .from('triage_patients')
          .select(
            '*, patients:patient_id(full_name, phone), nurses:triage_nurse_id(full_name), doctors:assigned_doctor_id(full_name)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return TriagePatient.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load triage patient: $e');
    }
  }

  Future<TriagePatient> createPatient(TriagePatient patient) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = patient
          .copyWith(
            id: newId,
            arrivalTime: now,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'patient_phone' ||
            key == 'nurse_name' ||
            key == 'doctor_name',
      );

      final response = await _client
          .from('triage_patients')
          .insert(data)
          .select()
          .single();
      return TriagePatient.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create triage patient: $e');
    }
  }

  Future<TriagePatient> updatePatient(TriagePatient patient) async {
    try {
      final data = patient
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'patient_phone' ||
            key == 'nurse_name' ||
            key == 'doctor_name',
      );

      final response = await _client
          .from('triage_patients')
          .update(data)
          .eq('id', patient.id)
          .select()
          .single();
      return TriagePatient.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update triage patient: $e');
    }
  }

  Future<TriagePatient> updatePatientStatus(
    String id,
    TriageStatus newStatus, {
    String? notes,
    String? assignedDepartment,
    String? assignedDoctorId,
  }) async {
    try {
      final data = {
        'status': newStatus.name,
        if (notes != null) 'notes': notes,
        if (assignedDepartment != null)
          'assigned_department': assignedDepartment,
        if (assignedDoctorId != null) 'assigned_doctor_id': assignedDoctorId,
        if (newStatus == TriageStatus.discharged)
          'discharged_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('triage_patients')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return TriagePatient.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update patient status: $e');
    }
  }

  Future<void> deletePatient(String id) async {
    try {
      await _client.from('triage_patients').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete triage patient: $e');
    }
  }

  // ---- Assessments ----

  Future<List<TriageAssessment>> getAssessmentsForPatient(
    String triagePatientId,
  ) async {
    try {
      final response = await _client
          .from('triage_assessments')
          .select('*, nurses:nurse_id(full_name)')
          .eq('triage_patient_id', triagePatientId)
          .order('assessment_time', ascending: false);
      return (response as List)
          .map((e) => TriageAssessment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load assessments: $e');
    }
  }

  Future<TriageAssessment> createAssessment(TriageAssessment assessment) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = assessment
          .copyWith(
            id: newId,
            assessmentTime: now,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere((key, value) => key == 'nurse_name');

      final response = await _client
          .from('triage_assessments')
          .insert(data)
          .select()
          .single();
      return TriageAssessment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create assessment: $e');
    }
  }

  Future<TriageAssessment> updateAssessment(TriageAssessment assessment) async {
    try {
      final data = assessment
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere((key, value) => key == 'nurse_name');

      final response = await _client
          .from('triage_assessments')
          .update(data)
          .eq('id', assessment.id)
          .select()
          .single();
      return TriageAssessment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update assessment: $e');
    }
  }

  Future<void> deleteAssessment(String id) async {
    try {
      await _client.from('triage_assessments').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete assessment: $e');
    }
  }
}
