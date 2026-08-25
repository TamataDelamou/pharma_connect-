import 'dart:math';
import '../models/cold_equipment.dart';
import '../models/equipment_type.dart';
import '../models/equipment_status.dart';
import '../models/temperature_record.dart';
import '../models/record_type.dart';
import '../models/cold_incident.dart';

class ColdChainService {
  static final List<ColdEquipment> _equipments = [];
  static final List<TemperatureRecord> _temperatureRecords = [];
  static final List<ColdIncident> _incidents = [];
  static final Random _random = Random();

  // ==================== DONNÉES MOCKÉES ====================

  static final List<ColdEquipment> _mockEquipments = [
    ColdEquipment(
      id: 'eq_001',
      name: 'Réfrigérateur Principal',
      type: EquipmentType.refrigerator,
      status: EquipmentStatus.operational,
      serialNumber: 'REF-2024-001',
      model: 'Vestfrost CFF-300',
      manufacturer: 'Vestfrost',
      minTemperature: 2,
      maxTemperature: 8,
      currentTemperature: 4.5,
      lastCalibrationDate: DateTime.now().subtract(const Duration(days: 30)),
      nextCalibrationDate: DateTime.now().add(const Duration(days: 335)),
      location: 'Zone de stockage A',
      pharmacyId: 'ph_001',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
    ColdEquipment(
      id: 'eq_002',
      name: 'Congélateur Vaccins',
      type: EquipmentType.freezer,
      status: EquipmentStatus.operational,
      serialNumber: 'FRZ-2024-002',
      model: 'Vestfrost CFF-200',
      manufacturer: 'Vestfrost',
      minTemperature: -25,
      maxTemperature: -15,
      currentTemperature: -19.5,
      lastCalibrationDate: DateTime.now().subtract(const Duration(days: 60)),
      nextCalibrationDate: DateTime.now().add(const Duration(days: 305)),
      location: 'Zone de stockage B',
      pharmacyId: 'ph_001',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
    ColdEquipment(
      id: 'eq_003',
      name: 'Glacière Transport',
      type: EquipmentType.transportBox,
      status: EquipmentStatus.operational,
      serialNumber: 'TRN-2024-003',
      model: 'B Medical BMS-10',
      manufacturer: 'B Medical',
      minTemperature: 2,
      maxTemperature: 8,
      currentTemperature: 6.2,
      lastCalibrationDate: DateTime.now().subtract(const Duration(days: 45)),
      nextCalibrationDate: DateTime.now().add(const Duration(days: 320)),
      location: 'Véhicule de livraison',
      pharmacyId: 'ph_001',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    ),
  ];

  static final List<TemperatureRecord> _mockRecords = [
    TemperatureRecord(
      id: 'rec_001',
      equipmentId: 'eq_001',
      temperature: 4.5,
      minTemperature: 2,
      maxTemperature: 8,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      type: RecordType.automatic,
      isAlert: false,
    ),
    TemperatureRecord(
      id: 'rec_002',
      equipmentId: 'eq_001',
      temperature: 4.8,
      minTemperature: 2,
      maxTemperature: 8,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: RecordType.automatic,
      isAlert: false,
    ),
    TemperatureRecord(
      id: 'rec_003',
      equipmentId: 'eq_002',
      temperature: -19.5,
      minTemperature: -25,
      maxTemperature: -15,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      type: RecordType.automatic,
      isAlert: false,
    ),
    TemperatureRecord(
      id: 'rec_004',
      equipmentId: 'eq_003',
      temperature: 6.2,
      minTemperature: 2,
      maxTemperature: 8,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      type: RecordType.manual,
      recordedBy: 'Pharmacien Martin',
      isAlert: false,
    ),
    TemperatureRecord(
      id: 'rec_005',
      equipmentId: 'eq_001',
      temperature: 9.5,
      minTemperature: 2,
      maxTemperature: 8,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: RecordType.automatic,
      isAlert: true,
      alertId: 'alt_001',
    ),
  ];

  static final List<ColdIncident> _mockIncidents = [
    ColdIncident(
      id: 'inc_001',
      equipmentId: 'eq_001',
      equipmentName: 'Réfrigérateur Principal',
      batchId: 'tb_001',
      batchNumber: 'DOL-2024-001',
      productName: 'Doliprane 1000mg',
      occurredAt: DateTime.now().subtract(const Duration(hours: 3)),
      temperatureRecorded: 9.5,
      minTemperature: 2,
      maxTemperature: 8,
      severity: IncidentSeverity.major,
      resolvedAt: DateTime.now().subtract(const Duration(hours: 2)),
      resolutionNotes:
          'Erreur de portefeuille, remise en route après vérification',
      reportedBy: 'Système automatique',
      isResolved: true,
    ),
  ];

  static void _initMockData() {
    if (_equipments.isEmpty) {
      _equipments.addAll(_mockEquipments);
    }
    if (_temperatureRecords.isEmpty) {
      _temperatureRecords.addAll(_mockRecords);
    }
    if (_incidents.isEmpty) {
      _incidents.addAll(_mockIncidents);
    }
  }

  // ==================== ÉQUIPEMENTS ====================

  Future<List<ColdEquipment>> getEquipments({String? pharmacyId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var list = _equipments;
    if (pharmacyId != null) {
      list = list.where((e) => e.pharmacyId == pharmacyId).toList();
    }
    return list;
  }

  Future<ColdEquipment> getEquipment(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _equipments.firstWhere((e) => e.id == id);
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
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    final equipment = ColdEquipment(
      id: 'eq_${DateTime.now().millisecondsSinceEpoch}',
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

    _equipments.add(equipment);
    return equipment;
  }

  Future<ColdEquipment> updateEquipment(
    String id,
    ColdEquipment updated,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final index = _equipments.indexWhere((e) => e.id == id);
    if (index == -1) throw Exception('Equipment not found');

    _equipments[index] = updated.copyWith(updatedAt: DateTime.now());
    return _equipments[index];
  }

  Future<ColdEquipment> updateTemperature(String id, double temperature) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();

    final index = _equipments.indexWhere((e) => e.id == id);
    if (index == -1) throw Exception('Equipment not found');

    final equipment = _equipments[index];
    final updated = equipment.copyWith(currentTemperature: temperature);

    // Vérifier si la température est hors plage
    if (temperature < equipment.minTemperature ||
        temperature > equipment.maxTemperature) {
      updated.copyWith(status: EquipmentStatus.alarm);
    } else {
      updated.copyWith(status: EquipmentStatus.operational);
    }

    _equipments[index] = updated;

    // Enregistrer la température
    await _saveTemperatureRecord(
      equipmentId: id,
      temperature: temperature,
      type: RecordType.automatic,
      isAlert: !updated.isTemperatureValid,
    );

    // Créer un incident si hors plage
    if (!updated.isTemperatureValid) {
      // Simuler la création d'un incident
      await _createIncident(equipmentId: id, temperature: temperature);
    }

    return _equipments[index];
  }

  // ==================== TEMPÉRATURES ====================

  Future<List<TemperatureRecord>> getTemperatureRecords({
    String? equipmentId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isAlert,
    int limit = 100,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var list = _temperatureRecords;

    if (equipmentId != null) {
      list = list.where((r) => r.equipmentId == equipmentId).toList();
    }

    if (fromDate != null) {
      list = list.where((r) => r.timestamp.isAfter(fromDate)).toList();
    }

    if (toDate != null) {
      list = list.where((r) => r.timestamp.isBefore(toDate)).toList();
    }

    if (isAlert != null) {
      list = list.where((r) => r.isAlert == isAlert).toList();
    }

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(limit).toList();
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
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      equipmentId: equipmentId,
      temperature: temperature,
      timestamp: DateTime.now(),
      type: type,
      recordedBy: recordedBy,
      notes: notes,
      isAlert: isAlert,
    );

    _temperatureRecords.add(record);

    // Créer une alerte via le module alerts si rupture
    if (isAlert) {
      // Simuler la création d'alerte
      // alertService.createAlert(...)
    }

    return record;
  }

  Future<TemperatureRecord> addManualTemperature({
    required String equipmentId,
    required double temperature,
    required String recordedBy,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final equipment = await getEquipment(equipmentId);
    final isAlert =
        temperature < equipment.minTemperature ||
        temperature > equipment.maxTemperature;

    return await _saveTemperatureRecord(
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
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var list = _incidents;

    if (equipmentId != null) {
      list = list.where((i) => i.equipmentId == equipmentId).toList();
    }

    if (batchId != null) {
      list = list.where((i) => i.batchId == batchId).toList();
    }

    if (isResolved != null) {
      list = list.where((i) => i.isResolved == isResolved).toList();
    }

    if (severity != null) {
      list = list.where((i) => i.severity == severity).toList();
    }

    list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list;
  }

  Future<ColdIncident> _createIncident({
    required String equipmentId,
    required double temperature,
    String? batchId,
  }) async {
    final equipment = await getEquipment(equipmentId);

    final incident = ColdIncident(
      id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
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

    _incidents.add(incident);
    return incident;
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
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final index = _incidents.indexWhere((i) => i.id == id);
    if (index == -1) throw Exception('Incident not found');

    final resolved = _incidents[index].copyWith(
      isResolved: true,
      resolvedAt: DateTime.now(),
      resolutionNotes: resolutionNotes,
    );

    _incidents[index] = resolved;
    return resolved;
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getStatistics({String? pharmacyId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var equipments = _equipments;
    if (pharmacyId != null) {
      equipments = equipments.where((e) => e.pharmacyId == pharmacyId).toList();
    }

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

    return {
      'totalEquipments': equipments.length,
      'operational': operational,
      'alarms': alarms,
      'maintenance': maintenance,
      'recentAlerts': alerts,
      'activeIncidents': _incidents.where((i) => !i.isResolved).length,
    };
  }
}
