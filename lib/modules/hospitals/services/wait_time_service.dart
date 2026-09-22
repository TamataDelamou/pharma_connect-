import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/hospital_wait_time.dart';

class WaitTimeService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  Future<List<HospitalWaitTime>> getWaitTimes(String hospitalId) async {
    try {
      final response = await _client
          .from('hospital_wait_times')
          .select()
          .eq('hospital_id', hospitalId)
          .order('wait_time_minutes', ascending: true);
      return (response as List)
          .map((e) => HospitalWaitTime.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load wait times: $e');
    }
  }

  Future<HospitalWaitTime> updateWaitTime({
    required String hospitalId,
    required String department,
    required int waitTime,
    int patientsInQueue = 0,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final data = {
        'hospital_id': hospitalId,
        'department': department,
        'wait_time_minutes': waitTime,
        'patients_in_queue': patientsInQueue,
        'last_updated': now.toIso8601String(),
        'is_accurate': true,
        'updated_at': now.toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('hospital_wait_times')
          .upsert(data, onConflict: 'hospital_id,department')
          .select()
          .single();
      return HospitalWaitTime.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update wait time: $e');
    }
  }
}
