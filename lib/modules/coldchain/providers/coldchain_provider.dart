import 'package:flutter/material.dart';
import '../models/cold_equipment.dart';
import '../models/equipment_type.dart';
import '../models/equipment_status.dart';
import '../models/temperature_record.dart';
import '../models/cold_incident.dart';
import '../services/coldchain_service.dart';

class ColdChainProvider extends ChangeNotifier {
  final ColdChainService _service = ColdChainService();

  List<ColdEquipment> _equipments = [];
  ColdEquipment? _selectedEquipment;
  List<TemperatureRecord> _temperatureRecords = [];
  List<ColdIncident> _incidents = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ColdEquipment> get equipments => _equipments;
  ColdEquipment? get selectedEquipment => _selectedEquipment;
  List<TemperatureRecord> get temperatureRecords => _temperatureRecords;
  List<ColdIncident> get incidents => _incidents;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ColdEquipment> get activeEquipments =>
      _equipments.where((e) => e.isActive).toList();

  List<ColdEquipment> get alarmEquipments =>
      _equipments.where((e) => e.status == EquipmentStatus.alarm).toList();

  List<ColdIncident> get unresolvedIncidents =>
      _incidents.where((i) => !i.isResolved).toList();

  // ==================== CHARGEMENT ====================

  Future<void> loadEquipments({String? pharmacyId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _equipments = await _service.getEquipments(pharmacyId: pharmacyId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadEquipment(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedEquipment = await _service.getEquipment(id);
      if (_selectedEquipment != null) {
        _temperatureRecords = await _service.getTemperatureRecords(
          equipmentId: id,
          limit: 50,
        );
        _incidents = await _service.getIncidents(equipmentId: id);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStatistics({String? pharmacyId}) async {
    try {
      _statistics = await _service.getStatistics(pharmacyId: pharmacyId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== ACTIONS ====================

  Future<ColdEquipment?> createEquipment({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final equipment = await _service.createEquipment(
        name: name,
        type: type,
        serialNumber: serialNumber,
        model: model,
        manufacturer: manufacturer,
        minTemperature: minTemperature,
        maxTemperature: maxTemperature,
        location: location,
        pharmacyId: pharmacyId,
        notes: notes,
      );
      _equipments.add(equipment);
      _isLoading = false;
      notifyListeners();
      return equipment;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTemperature(String equipmentId, double temperature) async {
    try {
      final updated = await _service.updateTemperature(
        equipmentId,
        temperature,
      );
      _updateEquipment(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addManualTemperature({
    required String equipmentId,
    required double temperature,
    required String recordedBy,
    String? notes,
  }) async {
    try {
      final record = await _service.addManualTemperature(
        equipmentId: equipmentId,
        temperature: temperature,
        recordedBy: recordedBy,
        notes: notes,
      );
      _temperatureRecords.insert(0, record);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolveIncident(String id, {String? resolutionNotes}) async {
    try {
      final resolved = await _service.resolveIncident(
        id,
        resolutionNotes: resolutionNotes,
      );
      final index = _incidents.indexWhere((i) => i.id == id);
      if (index != -1) {
        _incidents[index] = resolved;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== UTILITAIRES ====================

  void _updateEquipment(ColdEquipment updated) {
    final index = _equipments.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _equipments[index] = updated;
    }
    if (_selectedEquipment?.id == updated.id) {
      _selectedEquipment = updated;
    }
    notifyListeners();
  }

  void clearSelected() {
    _selectedEquipment = null;
    _temperatureRecords = [];
    _incidents = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
