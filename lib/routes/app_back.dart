import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// C226 : retour commun (flèche de la barre du haut et bouton retour du
/// système) :
/// 1. si la pile le permet, `pop` ;
/// 2. sinon, la route parente (l'adresse sans son dernier segment), si elle
///    existe dans le routeur ;
/// 3. sinon, /dashboard.
///
/// La parente est cherchée sur le motif de la route : `/family/challenges/:id`
/// donne `/family/challenges`, qui doit être déclaré tel quel. Comparer les
/// adresses concrètes ferait correspondre `/family/challenges` au motif
/// `/family/:id` (détail d'une famille dont l'identifiant serait
/// « challenges »).
void goBack(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  final current = router.state;
  router.go(
    parentLocation(
          pattern: current.fullPath ?? current.uri.path,
          path: current.uri.path,
          declaredPatterns: declaredRoutePatterns(router.configuration.routes),
        ) ??
        '/dashboard',
  );
}

/// Adresse parente, ou null s'il n'y en a pas (racine, ou parente absente du
/// routeur).
String? parentLocation({
  required String pattern,
  required String path,
  required Set<String> declaredPatterns,
}) {
  final patternSegments = _segments(pattern);
  final pathSegments = _segments(path);
  if (patternSegments.length < 2 ||
      patternSegments.length != pathSegments.length) {
    return null;
  }
  final parentPattern =
      '/${patternSegments.sublist(0, patternSegments.length - 1).join('/')}';
  if (!declaredPatterns.contains(parentPattern)) return null;
  return '/${pathSegments.sublist(0, pathSegments.length - 1).join('/')}';
}

/// Motifs complets de toutes les GoRoute déclarées (les routes de ce projet
/// sont toutes absolues, y compris dans la ShellRoute).
Set<String> declaredRoutePatterns(List<RouteBase> routes) {
  final patterns = <String>{};
  void visit(List<RouteBase> routes) {
    for (final route in routes) {
      if (route is GoRoute) patterns.add(route.path);
      visit(route.routes);
    }
  }

  visit(routes);
  return patterns;
}

List<String> _segments(String path) =>
    path.split('?').first.split('/').where((s) => s.isNotEmpty).toList();
