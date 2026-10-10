import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/core/utils/pharmacy_position.dart';

// C252 : contrôle de la position d'une officine.
void main() {
  group('PharmacyPosition.validate', () {
    test('accepte un point valide', () {
      expect(PharmacyPosition.validate(9.5370, -13.6785), isNull);
    });

    test('accepte les bornes', () {
      expect(PharmacyPosition.validate(-90, -180), isNull);
      expect(PharmacyPosition.validate(90, 180), isNull);
    });

    test('refuse une latitude hors de [-90 ; 90]', () {
      expect(PharmacyPosition.validate(90.01, 0), contains('Latitude'));
      expect(PharmacyPosition.validate(-91, 0), contains('Latitude'));
    });

    test('refuse une longitude hors de [-180 ; 180]', () {
      expect(PharmacyPosition.validate(0, 180.5), contains('Longitude'));
      expect(PharmacyPosition.validate(0, -181), contains('Longitude'));
    });

    test('refuse une valeur absente ou non numérique', () {
      expect(PharmacyPosition.validate(null, -13.6), contains('Latitude'));
      expect(PharmacyPosition.validate(9.5, null), contains('Longitude'));
      expect(PharmacyPosition.validate(double.nan, -13.6), isNotNull);
    });
  });

  group('PharmacyPosition.isOutsideGuinea', () {
    test('Conakry, Kankan et Nzérékoré sont en Guinée', () {
      expect(PharmacyPosition.isOutsideGuinea(9.5370, -13.6785), isFalse);
      expect(PharmacyPosition.isOutsideGuinea(10.3854, -9.3057), isFalse);
      expect(PharmacyPosition.isOutsideGuinea(7.7562, -8.8179), isFalse);
    });

    test('latitude et longitude inversées : hors de la Guinée', () {
      expect(PharmacyPosition.isOutsideGuinea(-13.6785, 9.5370), isTrue);
    });

    test('Dakar, Paris et le point (0, 0) sont hors de la Guinée', () {
      expect(PharmacyPosition.isOutsideGuinea(14.7167, -17.4677), isTrue);
      expect(PharmacyPosition.isOutsideGuinea(48.8566, 2.3522), isTrue);
      expect(PharmacyPosition.isOutsideGuinea(0, 0), isTrue);
    });

    // Limite connue : l'emprise est un rectangle, pas la frontière.
    test('Freetown et Bamako, dans le rectangle, ne sont pas signalées', () {
      expect(PharmacyPosition.isOutsideGuinea(8.4844, -13.2344), isFalse);
      expect(PharmacyPosition.isOutsideGuinea(12.6392, -8.0029), isFalse);
    });

    test('un point valide hors de la Guinée reste accepté', () {
      expect(PharmacyPosition.validate(14.7167, -17.4677), isNull);
    });
  });
}
