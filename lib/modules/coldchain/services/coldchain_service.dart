import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/cold_equipment.dart';
import '../models/equipment_type.dart';
import '../models/equipment_status.dart';
import '../models/temperature_record.dart';
import '../models/record_type.dart';
import '../models/cold_incident.dart';
import '../../../core/services/supabase_service.dart';

class ColdChainService {
  SupabaseClient get _client => SupabaseService().client;

  // ==================== ÉQUIPEMENTS ====================

  Future<List<ColdEquipment>> getEquipments({String? pharmacyId}) async {
    var query = _client.from('cold_equipment').select();
    if (pharmacyId != null) {
      query = query.eq('pharmacy_id', pharmacyId);
    }
    final rows = await query;
    return rows.map((row) => ColdEquipment.fromJson(row)).toList();
  }

  Future<ColdEquipment> getEquipment(String id) async {
    final row = await _client
        .from('cold_equipment')
        .select()
        .eq('id', id)
        .single();
    return ColdEquipment.fromJson(row);
  }

  Future<ColdEquipment> createEquipment({
    required String name,
    required EquipmentType type,
    required String serialNumber,
    required String model,
    required String manufacturer,
    double? minTemperature,
    double? maxTemperature,
    String? location,
    String? pharmacyId,
    String? notes,
  }) async {
    final equipment = ColdEquipment(
      id: const Uuid().v4(),
      name: name,
      type: type,
      status: EquipmentStatus.operational,
      serialNumber: serialNumber,
      model: model,
      manufacturer: manufacturer,
      minTemperature: minTemperature ?? type.defaultMinTemperature,
      maxTemperature: maxTemperature ?? type.defaultMaxTemperature,
      currentTemperature:
          (type.defaultMinTemperature + type.defaultMaxTemperature) / 2,
      location: location,
      pharmacyId: pharmacyId,
      isActive: true,
      createdAt: DateTime.now(),
      notes: notes,
    );

    final row = await _client
        .from('cold_equipment')
        .insert(equipment.toJson())
        .select()
        .single();
    return ColdEquipment.fromJson(row);
  }

  Future<ColdEquipment> updateEquipment(
    String id,
    ColdEquipment updated,
  ) async {
    final payload = updated.toJson()..remove('id');
    final row = await _client
        .from('cold_equipment')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return ColdEquipment.fromJson(row);
  }

  Future<ColdEquipment> updateTemperature(String id, double temperature) async {
    final equipment = await getEquipment(id);
    final isValid =
        temperature >= equipment.minTemperature &&
        temperature <= equipment.maxTemperature;

    final row = await _client
        .from('cold_equipment')
        .update({
          'current_temperature': temperature,
          'status': (isValid
                  ? EquipmentStatus.operational
                  : EquipmentStatus.alarm)
              .name,
        })
        .eq('id', id)
        .select()
        .single();
    final updated = ColdEquipment.fromJson(row);

    await _saveTemperatureRecord(
      equipmentId: id,
      temperature: temperature,
      type: RecordType.automatic,
      isAlert: !isValid,
    );

    if (!isValid) {
      await _createIncident(equipmentId: id, temperature: temperature);
    }

    return updated;
  }

  // ==================== TEMPÉRATURES ====================

  Future<List<TemperatureRecord>> getTemperatureRecords({
    String? equipmentId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isAlert,
    int limit = 100,
  }) async {
    var query = _client.from('temperature_records').select();

    if (equipmentId != null) {
      query = query.eq('equipment_id', equipmentId);
    }
    if (fromDate != null) {
      query = query.gt('timestamp', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lt('timestamp', toDate.toIso8601String());
    }
    if (isAlert != null) {
      query = query.eq('is_alert', isAlert);
    }

    final rows = await query.order('timestamp', ascending: false).limit(limit);
    return rows.map((row) => TemperatureRecord.fromJson(row)).toList();
  }

  Future<TemperatureRecord> _saveTemperatureRecord({
    required String equipmentId,
    required double temperature,
    required RecordType type,
    bool isAlert = false,
    String? recordedBy,
    String? notes,
  }) async {
    final record = TemperatureRecord(
      id: const Uuid().v4(),
      equipmentId: equipmentId,
      temperature: temperature,
      timestamp: DateTime.now(),
      type: type,
      recordedBy: recordedBy,
      notes: notes,
      isAlert: isAlert,
    );

    final row = await _client
        .from('temperature_records')
        .insert(record.toJson())
        .select()
        .single();

    // Créer une alerte via le module alerts si rupture — voir
    // AlertService.generateExpiryAlert/createAlert pour le patron équivalent.
    return TemperatureRecord.fromJson(row);
  }

  Future<TemperatureRecord> addManualTemperature({
    required String equipmentId,
    required double temperature,
    required String recordedBy,
    String? notes,
  }) async {
    final equipment = await getEquipment(equipmentId);
    final isAlert =
        temperature < equipment.minTemperature ||
        temperature > equipment.maxTemperature;

    return _saveTemperatureRecord(
      equipmentId: equipmentId,
      temperature: temperature,
      type: RecordType.manual,
      isAlert: isAlert,
      recordedBy: recordedBy,
      notes: notes,
    );
  }

  // ==================== INCIDENTS ====================

  Future<List<ColdIncident>> getIncidents({
    String? equipmentId,
    String? batchId,
    bool? isResolved,
    IncidentSeverity? severity,
  }) async {
    var query = _client.from('cold_incidents').select();

    if (equipmentId != null) {
      query = query.eq('equipment_id', equipmentId);
    }
    if (batchId != null) {
      query = query.eq('batch_id', batchId);
    }
    if (isResolved != null) {
      query = query.eq('is_resolved', isResolved);
    }
    if (severity != null) {
      query = query.eq('severity', severity.name);
    }

    final rows = await query.order('occurred_at', ascending: false);
    return rows.map((row) => ColdIncident.fromJson(row)).toList();
  }

  Future<ColdIncident> _createIncident({
    required String equipmentId,
    required double temperature,
    String? batchId,
  }) async {
    final equipment = await getEquipment(equipmentId);

    final incident = ColdIncident(
      id: const Uuid().v4(),
      equipmentId: equipmentId,
      equipmentName: equipment.name,
      batchId: batchId ?? 'unknown',
      batchNumber: batchId ?? 'unknown',
      productName: 'Produit inconnu',
      occurredAt: DateTime.now(),
      temperatureRecorded: temperature,
      minTemperature: equipment.minTemperature,
      maxTemperature: equipment.maxTemperature,
      severity: _calculateSeverity(
        temperature,
        equipment.minTemperature,
        equipment.maxTemperature,
      ),
      reportedBy: 'Système automatique',
      isResolved: false,
    );

    final row = await _client
        .from('cold_incidents')
        .insert(incident.toJson())
        .select()
        .single();
    return ColdIncident.fromJson(row);
  }

  IncidentSeverity _calculateSeverity(
    double temperature,
    double min,
    double max,
  ) {
    final diff = (temperature - min).abs() > (temperature - max).abs()
        ? (temperature - max).abs()
        : (temperature - min).abs();

    if (diff > 5) return IncidentSeverity.critical;
    if (diff > 2) return IncidentSeverity.major;
    return IncidentSeverity.minor;
  }

  Future<ColdIncident> resolveIncident(
    String id, {
    String? resolutionNotes,
  }) async {
    final row = await _client
        .from('cold_incidents')
        .update({
          'is_resolved': true,
          'resolved_at': DateTime.now().toIso8601String(),
          'resolution_notes': resolutionNotes,
        })
        .eq('id', id)
        .select()
        .single();
    return ColdIncident.fromJson(row);
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getStatistics({String? pharmacyId}) async {
    final equipments = await getEquipments(pharmacyId: pharmacyId);

    final operational = equipments
        .where((e) => e.status == EquipmentStatus.operational)
        .length;
    final alarms = equipments
        .where((e) => e.status == EquipmentStatus.alarm)
        .length;
    final maintenance = equipments
        .where((e) => e.status == EquipmentStatus.maintenance)
        .length;

    final recentRecords = await getTemperatureRecords(limit: 100);
    final alerts = recentRecords.where((r) => r.isAlert).length;
    final incidents = await getIncidents(isResolved: false);

    return {
      'totalEquipments': equipments.length,
      'operational': operational,
      'alarms': alarms,
      'maintenance': maintenance,
      'recentAlerts': alerts,
      'activeIncidents': incidents.length,
    };
  }
}
