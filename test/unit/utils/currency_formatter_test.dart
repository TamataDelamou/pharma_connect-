import 'package:flutter_test/flutter_test.dart';

import 'package:pharma_connect/core/utils/currency_formatter.dart';

// C267 : montants au format français, avec des espaces insécables entre les
// groupes de chiffres et avant « GNF » : un montant n'est jamais coupé en fin
// de ligne.

/// Écrit l'attendu avec des espaces ordinaires, lisibles dans ce fichier ;
/// elles sont remplacées ici par l'espace insécable (U+00A0).
String _expected(String text) => text.replaceAll(' ', CurrencyFormatter.nbsp);

void main() {
  group('format', () {
    final cases = <num, String>{
      0: '0 GNF',
      7: '7 GNF',
      999: '999 GNF',
      1000: '1 000 GNF',
      1575: '1 575 GNF',
      16075: '16 075 GNF',
      150000: '150 000 GNF',
      1234567: '1 234 567 GNF',
      1574.6: '1 575 GNF',
    };
    cases.forEach((amount, text) {
      test('$amount', () {
        expect(CurrencyFormatter.format(amount), _expected(text));
      });
    });

    test('montant négatif : signe moins typographique', () {
      expect(
        CurrencyFormatter.format(-1500),
        '${CurrencyFormatter.minus}${_expected('1 500 GNF')}',
      );
      expect(CurrencyFormatter.minus.codeUnitAt(0), 0x2212);
    });

    test('jamais d\'espace sécable : le montant ne se coupe pas', () {
      final text = CurrencyFormatter.format(150000);
      expect(text.contains(' '), isFalse);
      expect(CurrencyFormatter.nbsp.codeUnitAt(0), 0x00A0);
    });
  });

  group('parse : montant saisi', () {
    test('avec ou sans séparateurs, avec ou sans « GNF »', () {
      expect(CurrencyFormatter.parse('10000'), 10000);
      expect(CurrencyFormatter.parse('10 000'), 10000);
      expect(CurrencyFormatter.parse(' 10 000 '), 10000);
      expect(CurrencyFormatter.parse(CurrencyFormatter.format(16075)), 16075);
      expect(CurrencyFormatter.parse('16075 gnf'), 16075);
      expect(CurrencyFormatter.parse('0'), 0);
    });

    test('saisie invalide : null', () {
      expect(CurrencyFormatter.parse(''), isNull);
      expect(CurrencyFormatter.parse('abc'), isNull);
      expect(CurrencyFormatter.parse('-1500'), isNull);
      expect(CurrencyFormatter.parse('1 500,50'), isNull);
    });
  });
}
