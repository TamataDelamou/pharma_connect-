import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pharma_connect/core/pilot/pilot_config.dart';
import 'package:pharma_connect/modules/auth/models/user_role.dart';
import 'package:pharma_connect/modules/dashboard/providers/dashboard_provider.dart';
import 'package:pharma_connect/routes/app_menu.dart';

// C263 : garde-fou permanent. Dans les modules du pilote, une erreur ne doit
// jamais être rangée ni affichée telle quelle (`e.toString()`, `'… $e'`) :
// elle passe par userMessage (core/utils/user_message.dart).
//
// Les modules hors pilote ne sont pas encore traités : décision d'Achille du
// 13/10/2026, à faire avant l'ouverture de l'un d'eux (registre, C263).
//
// C270 : la liste des modules du pilote n'est plus écrite à la main (le
// catalogue y manquait). Elle est déduite des routes atteignables pendant le
// pilote : menu de chaque rôle (appMenuFor, qui suit PilotConfig), raccourcis
// du tableau de bord et parcours de connexion (routes hors du cadre commun).
// Chaque route mène, par app_router.dart, à un écran, et l'écran à son
// module.

const _routerPath = 'lib/routes/app_router.dart';

/// Une erreur attrapée transformée directement en texte.
final _rawError = RegExp(
  r'''(\b(e|err|error)\.toString\(\))|(['"][^'"\n]*\$\{?(e|err|error)\}?\b)''',
);

/// C270 : l'erreur d'un fournisseur insérée dans un texte
/// (« Erreur : ${provider.error} »). Le message est déjà rédigé par
/// userMessage ; un préfixe « Erreur : » le rend technique, et rien ne
/// garantit que l'erreur insérée a été traduite.
final _interpolatedError = RegExp(
  r'''['"][^'"\n]*\$\{(?:[\w?!]*\.)*_?error!?\}''',
);

/// Routes atteignables pendant le pilote, avec leur origine.
Map<String, String> _pilotRoutes(String router) {
  final routes = <String, String>{};
  for (final role in [null, ...UserRole.values]) {
    for (final admin in [false, true]) {
      for (final item in appMenuFor(role, isGsgAdmin: admin)) {
        routes.putIfAbsent(item.route, () => 'menu');
      }
    }
  }
  for (final action in DashboardProvider().data.actions) {
    routes.putIfAbsent(action.route, () => 'tableau de bord');
  }
  // Parcours de connexion : routes déclarées avant le cadre commun
  // (ShellRoute), sauf `/` qui redirige.
  final beforeShell = router.substring(0, router.indexOf('ShellRoute('));
  for (final m in RegExp(r"path: '([^']+)'").allMatches(beforeShell)) {
    if (m.group(1) != '/') routes.putIfAbsent(m.group(1)!, () => 'connexion');
  }
  return routes;
}

/// Écran construit par la route [route] dans app_router.dart.
String? _screenOf(String router, String route) {
  final start = router.indexOf("path: '$route',");
  if (start < 0) return null;
  final next = router.indexOf('GoRoute(', start);
  final block = router.substring(start, next < 0 ? router.length : next);
  return RegExp(r'\b([A-Z]\w*Screen)\(').firstMatch(block)?.group(1);
}

/// Module (dossier sous lib/modules) qui déclare la classe [screen].
String? _moduleOf(String screen, List<File> moduleFiles) {
  final declaration = RegExp('class $screen\\b');
  for (final file in moduleFiles) {
    if (!declaration.hasMatch(file.readAsStringSync())) continue;
    final parts = file.path.replaceAll('\\', '/').split('/');
    return parts[parts.indexOf('modules') + 1];
  }
  return null;
}

/// Modules du pilote, déduits des routes.
Set<String> pilotModules() {
  final router = File(_routerPath).readAsStringSync();
  final moduleFiles = Directory('lib/modules')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
  final modules = <String>{};
  final unresolved = <String>[];
  _pilotRoutes(router).forEach((route, origin) {
    final screen = _screenOf(router, route);
    final module = screen == null ? null : _moduleOf(screen, moduleFiles);
    if (module == null) {
      unresolved.add('$route ($origin) : écran ${screen ?? 'introuvable'}');
    } else {
      modules.add(module);
    }
  });
  // Une route du pilote sans écran dans un module serait un trou du
  // garde-fou : on le dit plutôt que de l'ignorer.
  expect(unresolved, isEmpty, reason: unresolved.join('\n'));
  return modules;
}

void main() {
  test('modules du pilote déduits des routes visibles', () {
    final modules = pilotModules();
    // Modules de l'ancienne liste écrite à la main : aucun ne doit sortir.
    expect(
      modules,
      containsAll(<String>[
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
      ]),
    );
    // C270 : le catalogue y manquait.
    expect(modules, contains('catalog'));
    // « Objectifs santé » est dans le menu pendant le pilote.
    expect(modules, contains('healthrecord'));
    // « Livraisons » est masqué pendant le pilote (C239).
    expect(modules.contains('delivery'), PilotConfig.reservationDelivery);
  });

  test('aucune erreur brute dans les fournisseurs et les écrans du pilote', () {
    final offenders = <String>[];
    for (final module in pilotModules()) {
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
          if (_rawError.hasMatch(line) || _interpolatedError.hasMatch(line)) {
            offenders.add('${file.path}:${i + 1}  $line');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('le garde-fou repère une erreur insérée dans un texte', () {
    for (final line in [
      "'Erreur : \${provider.error}',",
      "Text('Erreur : \${provider.error!}')",
      "'Échec : \${_error}'",
      "\"\${error}\"",
    ]) {
      expect(_interpolatedError.hasMatch(line), isTrue, reason: line);
    }
    for (final line in [
      'Text(provider.error!)',
      "provider.error ?? 'Action impossible.'",
      "'\${provider.errorCount} erreurs'",
    ]) {
      expect(_interpolatedError.hasMatch(line), isFalse, reason: line);
    }
  });
}
