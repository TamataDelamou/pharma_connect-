import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// C263 : garde-fou permanent. Dans les modules du pilote, une erreur ne doit
// jamais être rangée ni affichée telle quelle (`e.toString()`, `'… $e'`) :
// elle passe par userMessage (core/utils/user_message.dart).
//
// Les modules hors pilote ne sont pas encore traités : décision d'Achille du
// 13/10/2026, à faire avant l'ouverture de l'un d'eux (registre, C263).

const _pilotModules = [
  'reservations',
  'search',
  'cash',
  'pos',
  'stock',
  'prescriptions',
  'admin',
  'auth',
  'dashboard',
  'pharmacy_staff',
];

/// Une erreur attrapée transformée directement en texte.
final _rawError = RegExp(
  r'''(\b(e|err|error)\.toString\(\))|(['"][^'"\n]*\$\{?(e|err|error)\}?\b)''',
);

void main() {
  test('aucune erreur brute dans les fournisseurs et les écrans du pilote', () {
    final offenders = <String>[];
    for (final module in _pilotModules) {
      final dir = Directory('lib/modules/$module');
      if (!dir.existsSync()) continue;
      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        // Les services traduisent eux-mêmes les refus du serveur et
        // enveloppent les erreurs : ils ne parlent pas à l'écran.
        if (file.path.contains(
          '${Platform.pathSeparator}services${Platform.pathSeparator}',
        )) {
          continue;
        }
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('//')) continue;
          if (line.contains('debugPrint(')) continue;
          if (_rawError.hasMatch(line)) {
            offenders.add('${file.path}:${i + 1}  $line');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
