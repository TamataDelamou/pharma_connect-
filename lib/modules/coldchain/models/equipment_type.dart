enum EquipmentType { refrigerator, freezer, coldRoom, transportBox, coolBox }

extension EquipmentTypeExtension on EquipmentType {
  String get label {
    switch (this) {
      case EquipmentType.refrigerator:
        return 'Réfrigérateur';
      case EquipmentType.freezer:
        return 'Congélateur';
      case EquipmentType.coldRoom:
        return 'Chambre froide';
      case EquipmentType.transportBox:
        return 'Conteneur de transport';
      case EquipmentType.coolBox:
        return 'Glacière';
    }
  }

  String get icon {
    switch (this) {
      case EquipmentType.refrigerator:
        return '🧊';
      case EquipmentType.freezer:
        return '❄️';
      case EquipmentType.coldRoom:
        return '🏭';
      case EquipmentType.transportBox:
        return '📦';
      case EquipmentType.coolBox:
        return '🎒';
    }
  }

  double get defaultMinTemperature {
    switch (this) {
      case EquipmentType.refrigerator:
        return 2;
      case EquipmentType.freezer:
        return -20;
      case EquipmentType.coldRoom:
        return 2;
      case EquipmentType.transportBox:
        return 2;
      case EquipmentType.coolBox:
        return 2;
    }
  }

  double get defaultMaxTemperature {
    switch (this) {
      case EquipmentType.refrigerator:
        return 8;
      case EquipmentType.freezer:
        return -15;
      case EquipmentType.coldRoom:
        return 8;
      case EquipmentType.transportBox:
        return 8;
      case EquipmentType.coolBox:
        return 8;
    }
  }
}
