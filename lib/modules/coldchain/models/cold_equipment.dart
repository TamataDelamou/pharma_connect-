import 'equipment_type.dart';
import 'equipment_status.dart';
import '../../../core/theme/palette.dart';

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

  factory ColdEquipment.fromJson(Map<String, dynamic> json) => ColdEquipment(
    id: json['id'] as String,
    name: json['name'] as String,
    type: EquipmentType.values.byName(json['type'] as String),
    status: EquipmentStatus.values.byName(json['status'] as String),
    serialNumber: json['serial_number'] as String,
    model: json['model'] as String,
    manufacturer: json['manufacturer'] as String,
    minTemperature: (json['min_temperature'] as num).toDouble(),
    maxTemperature: (json['max_temperature'] as num).toDouble(),
    currentTemperature: (json['current_temperature'] as num).toDouble(),
    lastCalibrationDate: json['last_calibration_date'] != null
        ? DateTime.parse(json['last_calibration_date'] as String)
        : null,
    nextCalibrationDate: json['next_calibration_date'] != null
        ? DateTime.parse(json['next_calibration_date'] as String)
        : null,
    location: json['location'] as String?,
    pharmacyId: json['pharmacy_id'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'status': status.name,
    'serial_number': serialNumber,
    'model': model,
    'manufacturer': manufacturer,
    'min_temperature': minTemperature,
    'max_temperature': maxTemperature,
    'current_temperature': currentTemperature,
    'last_calibration_date': lastCalibrationDate?.toIso8601String(),
    'next_calibration_date': nextCalibrationDate?.toIso8601String(),
    'location': location,
    'pharmacy_id': pharmacyId,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'notes': notes,
  };

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

  ColorRole get statusColor {
    switch (status) {
      case EquipmentStatus.operational:
        return ColorRole.success;
      case EquipmentStatus.maintenance:
        return ColorRole.warning;
      case EquipmentStatus.alarm:
        return ColorRole.danger;
      case EquipmentStatus.offline:
        return ColorRole.textMuted;
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
