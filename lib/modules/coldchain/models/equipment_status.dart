enum EquipmentStatus { operational, maintenance, alarm, offline }

extension EquipmentStatusExtension on EquipmentStatus {
  String get label {
    switch (this) {
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
}
