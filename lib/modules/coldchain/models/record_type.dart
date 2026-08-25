enum RecordType { manual, automatic, sensor }

extension RecordTypeExtension on RecordType {
  String get label {
    switch (this) {
      case RecordType.manual:
        return 'Manuel';
      case RecordType.automatic:
        return 'Automatique';
      case RecordType.sensor:
        return 'Capteur IoT';
    }
  }
}
