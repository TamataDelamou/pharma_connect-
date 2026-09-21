import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/health_record.dart';

class HealthRecordService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  Future<List<HealthRecord>> getRecordsForPatient(String patientId) async {
    try {
      final response = await _client
          .from('health_records')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => HealthRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load health records: $e');
    }
  }

  Future<HealthRecord?> getRecord(String id) async {
    try {
      final response = await _client
          .from('health_records')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return HealthRecord.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load health record: $e');
    }
  }

  Future<HealthRecord> createRecord(HealthRecord record) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = record
          .copyWith(
            id: newId,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('health_records')
          .insert(data)
          .select()
          .single();
      return HealthRecord.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create health record: $e');
    }
  }

  Future<HealthRecord> updateRecord(HealthRecord record) async {
    try {
      final data = record
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('health_records')
          .update(data)
          .eq('id', record.id)
          .select()
          .single();
      return HealthRecord.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update health record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _client.from('health_records').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete health record: $e');
    }
  }
}
