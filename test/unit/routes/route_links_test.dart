import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// C231 : toute destination de navigation écrite en dur dans lib/ doit
// correspondre à une route déclarée dans lib/routes/app_router.dart.
// Un lien vers une route absente mène à la page « Page introuvable ».
//
// Sources recensées :
// - context.go / push / pushReplacement / replace('/…') ;
// - les champs `route:` et `actionRoute:` (barre latérale, actions rapides,
//   alertes) ;
// - les `return '/…'` des redirections du routeur.
// Les lignes commentées sont ignorées (routes désactivées, cf. C188).
// Les segments interpolés ($id, ${x.id}) correspondent à n'importe quel
// segment de la route.

/// Vide les lignes de commentaire (`//`, `///`) d'un fichier Dart, en
/// gardant la numérotation des lignes pour le rapport.
String _withoutCommentLines(String source) => source
    .split('\n')
    .map((line) => line.trimLeft().startsWith('//') ? '' : line)
    .join('\n');

List<String> _declaredRoutes() {
  final router = _withoutCommentLines(
    File('lib/routes/app_router.dart').readAsStringSync(),
  );
  return RegExp(
    r'''path:\s*['"]([^'"]+)['"]''',
  ).allMatches(router).map((m) => m.group(1)!).toList();
}

class _Link {
  final String file;
  final int line;
  final String target;
  const _Link(this.file, this.line, this.target);

  @override
  String toString() => '$file:$line -> $target';
}

final _linkPatterns = [
  RegExp(
    r'''context\s*\.\s*(?:go|push|pushReplacement|replace)\s*(?:<[^>]*>)?\(\s*['"]([^'"]+)['"]''',
  ),
  RegExp(r'''\b(?:route|actionRoute)\s*:\s*['"](/[^'"]*)['"]'''),
  RegExp(r'''return\s+['"](/[^'"]*)['"]'''),
];

List<_Link> _usedLinks() {
  final links = <_Link>[];
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    final source = _withoutCommentLines(file.readAsStringSync());
    for (final pattern in _linkPatterns) {
      for (final match in pattern.allMatches(source)) {
        final target = match.group(1)!;
        if (!target.startsWith('/')) continue;
        final line = '\n'.allMatches(source.substring(0, match.start)).length;
        links.add(_Link(file.path.replaceAll('\\', '/'), line + 1, target));
      }
    }
  }
  return links;
}

/// Chemin sans requête ni fragment, segments interpolés remplacés par `*`.
List<String> _segments(String path) {
  final clean = path.split('?').first.split('#').first;
  return clean
      .split('/')
      .where((s) => s.isNotEmpty)
      .map((s) => s.contains(r'$') ? '*' : s)
      .toList();
}

bool _matches(String link, String route) {
  final l = _segments(link);
  final r = _segments(route);
  if (l.length != r.length) return false;
  for (var i = 0; i < l.length; i++) {
    if (r[i].startsWith(':') || l[i] == '*') continue;
    if (l[i] != r[i]) return false;
  }
  return true;
}

void main() {
  test('le routeur déclare des routes', () {
    expect(_declaredRoutes(), isNotEmpty);
  });

  test('chaque lien de lib/ correspond à une route déclarée (C231)', () {
    final routes = _declaredRoutes();
    final links = _usedLinks();
    expect(links, isNotEmpty);
    final broken = links
        .where((link) => !routes.any((r) => _matches(link.target, r)))
        .toList();
    expect(
      broken,
      isEmpty,
      reason: 'Liens vers une route absente du routeur :\n${broken.join('\n')}',
    );
  });
}
