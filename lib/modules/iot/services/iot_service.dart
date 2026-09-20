import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/iot_device.dart';
import '../models/temperature_reading.dart';
import '../models/iot_alert.dart';

class IotService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Devices ----

  Future<List<IotDevice>> getDevices({
    String? pharmacyId,
    String? status,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('iot_devices').select();

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((e) => IotDevice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load devices: $e');
    }
  }

  Future<IotDevice?> getDevice(String id) async {
    try {
      final response = await _client
          .from('iot_devices')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return IotDevice.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load device: $e');
    }
  }

  Future<IotDevice> createDevice(IotDevice device) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = device
          .copyWith(
            id: id,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('iot_devices')
          .insert(data)
          .select()
          .single();
      return IotDevice.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create device: $e');
    }
  }

  Future<IotDevice> updateDevice(IotDevice device) async {
    try {
      final data = device
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('iot_devices')
          .update(data)
          .eq('id', device.id)
          .select()
          .single();
      return IotDevice.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update device: $e');
    }
  }

  Future<void> deleteDevice(String id) async {
    try {
      await _client.from('iot_devices').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete device: $e');
    }
  }

  // ---- Readings ----

  Future<List<TemperatureReading>> getTemperatureReadings({
    required String deviceId,
    int limit = 50,
    DateTime? fromDate,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('temperature_readings')
          .select()
          .eq('device_id', deviceId);

      if (fromDate != null) {
        query = query.gte('timestamp', fromDate.toIso8601String());
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => TemperatureReading.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load temperature readings: $e');
    }
  }

  Future<TemperatureReading> addTemperatureReading({
    required String deviceId,
    required double temperature,
    bool isAlert = false,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = {
        'id': id,
        'device_id': deviceId,
        'temperature': temperature,
        'timestamp': now.toIso8601String(),
        'is_alert': isAlert,
        'created_at': now.toIso8601String(),
      };
      final response = await _client
          .from('temperature_readings')
          .insert(data)
          .select()
          .single();
      return TemperatureReading.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add temperature reading: $e');
    }
  }

  // ---- Alerts ----

  Future<List<IotAlert>> getAlerts({String? deviceId, String? status}) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('iot_alerts').select();

      if (deviceId != null) {
        query = query.eq('device_id', deviceId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => IotAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load alerts: $e');
    }
  }

  Future<IotAlert> createAlert(IotAlert alert) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = alert
          .copyWith(
            id: id,
            status: 'active',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('iot_alerts')
          .insert(data)
          .select()
          .single();
      return IotAlert.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }

  Future<IotAlert> updateAlertStatus(String id, String newStatus) async {
    try {
      final data = {
        'status': newStatus,
        if (newStatus == 'acknowledged')
          'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
        if (newStatus == 'resolved')
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('iot_alerts')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return IotAlert.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update alert status: $e');
    }
  }

  // ---- Simulate device reading (for demo) ----

  Future<void> simulateReading(String deviceId) async {
    final device = await getDevice(deviceId);
    if (device == null) return;

    // Random temperature between 0 and 40
    final temp = 0 + (DateTime.now().millisecondsSinceEpoch % 400) / 10;
    final isAlert = temp > 30 || temp < 2;

    await addTemperatureReading(
      deviceId: deviceId,
      temperature: temp,
      isAlert: isAlert,
    );

    // Update device last_reading_at
    await _client
        .from('iot_devices')
        .update({'last_reading_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', deviceId);

    // Create alert if temperature out of range
    if (isAlert) {
      await createAlert(
        IotAlert(
          id: '',
          deviceId: deviceId,
          type: temp > 30 ? 'temperature_high' : 'temperature_low',
          message: 'Température ${temp.toStringAsFixed(1)}°C',
          value: temp,
          threshold: temp > 30 ? 30 : 2,
          status: 'active',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
  }
}
