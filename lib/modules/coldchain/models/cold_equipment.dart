import 'package:flutter/material.dart';
import 'equipment_type.dart';
import 'equipment_status.dart';

class ColdEquipment {
  final String id;
  final String name;
  final EquipmentType type;
  final EquipmentStatus status;
  final String serialNumber;
  final String model;
  final String manufacturer;
  final double minTemperature;
  final double maxTemperature;
  final double currentTemperature;
  final DateTime? lastCalibrationDate;
  final DateTime? nextCalibrationDate;
  final String? location;
  final String? pharmacyId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  ColdEquipment({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.serialNumber,
    required this.model,
    required this.manufacturer,
    required this.minTemperature,
    required this.maxTemperature,
    required this.currentTemperature,
    this.lastCalibrationDate,
    this.nextCalibrationDate,
    this.location,
    this.pharmacyId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  ColdEquipment copyWith({
    String? id,
    String? name,
    EquipmentType? type,
    EquipmentStatus? status,
    String? serialNumber,
    String? model,
    String? manufacturer,
    double? minTemperature,
    double? maxTemperature,
    double? currentTemperature,
    DateTime? lastCalibrationDate,
    DateTime? nextCalibrationDate,
    String? location,
    String? pharmacyId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return ColdEquipment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      serialNumber: serialNumber ?? this.serialNumber,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      lastCalibrationDate: lastCalibrationDate ?? this.lastCalibrationDate,
      nextCalibrationDate: nextCalibrationDate ?? this.nextCalibrationDate,
      location: location ?? this.location,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  String get statusLabel {
    switch (status) {
      case EquipmentStatus.operational:
        return 'Opérationnel';
      case EquipmentStatus.maintenance:
        return 'En maintenance';
      case EquipmentStatus.alarm:
        return 'Alarme';
      case EquipmentStatus.offline:
        return 'Hors ligne';
    }
  }

  Color get statusColor {
    switch (status) {
      case EquipmentStatus.operational:
        return Colors.green;
      case EquipmentStatus.maintenance:
        return Colors.orange;
      case EquipmentStatus.alarm:
        return Colors.red;
      case EquipmentStatus.offline:
        return Colors.grey;
    }
  }

  bool get isTemperatureValid =>
      currentTemperature >= minTemperature &&
      currentTemperature <= maxTemperature;

  String get temperatureStatus {
    if (currentTemperature < minTemperature) return '⏬ Trop froid';
    if (currentTemperature > maxTemperature) return '⏫ Trop chaud';
    return '✅ Conforme';
  }
}
