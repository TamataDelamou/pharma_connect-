import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/preventive_alert.dart';
import '../models/preventive_alert_history.dart';

class PreventiveAlertService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Alerts ----

  Future<List<PreventiveAlert>> getPatientAlerts(String patientId) async {
    try {
      final response = await _client
          .from('preventive_alerts')
          .select()
          .eq('patient_id', patientId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => PreventiveAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load preventive alerts: $e');
    }
  }

  Future<PreventiveAlert?> getAlert(String id) async {
    try {
      final response = await _client
          .from('preventive_alerts')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return PreventiveAlert.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load alert: $e');
    }
  }

  Future<PreventiveAlert> createAlert(PreventiveAlert alert) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = alert
          .copyWith(
            id: id,
            isActive: true,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('preventive_alerts')
          .insert(data)
          .select()
          .single();
      return PreventiveAlert.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create preventive alert: $e');
    }
  }

  Future<PreventiveAlert> updateAlert(PreventiveAlert alert) async {
    try {
      final data = alert
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('preventive_alerts')
          .update(data)
          .eq('id', alert.id)
          .select()
          .single();
      return PreventiveAlert.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update preventive alert: $e');
    }
  }

  Future<void> deleteAlert(String id) async {
    try {
      await _client.from('preventive_alerts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete preventive alert: $e');
    }
  }

  Future<void> toggleAlert(String id, bool isActive) async {
    try {
      await _client
          .from('preventive_alerts')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'updated_by': SupabaseService().currentUser?.id,
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to toggle alert: $e');
    }
  }

  // ---- Alert History ----

  Future<List<PreventiveAlertHistory>> getAlertHistory(String patientId) async {
    try {
      final response = await _client
          .from('preventive_alert_history')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);
      return (response as List)
          .map(
            (e) => PreventiveAlertHistory.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load alert history: $e');
    }
  }

  Future<void> updateAlertHistoryStatus(
    String id,
    String newStatus, {
    String? actionTaken,
  }) async {
    try {
      final data = {
        'status': newStatus,
        if (actionTaken != null) 'action_taken': actionTaken,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _client.from('preventive_alert_history').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update alert history: $e');
    }
  }

  // ---- Check and Trigger Alerts ----

  Future<void> checkAndTriggerAlerts(String patientId) async {
    try {
      final alerts = await getPatientAlerts(patientId);
      for (final alert in alerts) {
        if (await _evaluateCondition(patientId, alert)) {
          await _triggerAlert(patientId, alert);
        }
      }
    } catch (e) {
      // Silent fail - don't block user flow
    }
  }

  Future<bool> _evaluateCondition(
    String patientId,
    PreventiveAlert alert,
  ) async {
    final condition = alert.triggerCondition;
    final daysSince = condition['days_since'] as int?;
    final key = condition['key'] as String?;

    if (key == null || daysSince == null) return false;

    // Check last occurrence of this event type
    final tableName = key == 'vaccination'
        ? 'health_record_vaccinations'
        : 'health_actions';
    try {
      final response = await _client
          .from(tableName)
          .select('created_at')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return true; // No record, trigger

      final lastDate = DateTime.parse(response['created_at'] as String);
      final diff = DateTime.now().difference(lastDate).inDays;

      return diff >= daysSince;
    } catch (e) {
      return false;
    }
  }

  Future<void> _triggerAlert(String patientId, PreventiveAlert alert) async {
    try {
      // Create alert history entry
      await _client.from('preventive_alert_history').insert({
        'alert_id': alert.id,
        'patient_id': patientId,
        'sent_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update last_triggered
      await _client
          .from('preventive_alerts')
          .update({
            'last_triggered': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', alert.id);

      // TODO: Send notification via PushNotificationService
    } catch (e) {
      // Silent fail
    }
  }
}
