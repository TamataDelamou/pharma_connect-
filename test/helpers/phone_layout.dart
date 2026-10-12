import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pharma_connect/core/theme/adaptive_text_scale.dart';
import 'package:pharma_connect/core/theme/app_theme.dart';

// C253 : essais de mise en page en largeur téléphone. Un écran monté par
// [pumpAtPhoneWidth] ne doit signaler aucun débordement (bandeau rayé
// « OVERFLOWED BY … PIXELS » en mode « debug », contenu coupé sans aucun
// signe en version « release »).

/// Largeur du plus petit téléphone visé.
const Size phoneSize = Size(360, 780);

/// Charge la police de l'application : sans elle, les essais mesurent le
/// texte avec la police de test, bien plus large que la vraie.
Future<void> loadAppFonts() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File(
      'assets/fonts/Inter/Inter-$weight.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Exécute [body] et rend les débordements signalés pendant ce temps (« A
/// RenderFlex overflowed by … »). Les autres erreurs suivent leur cours, sauf
/// si [ignoreOtherErrors] est vrai (écran monté hors ligne, qui signale des
/// erreurs réseau).
/// Le gestionnaire d'erreurs est remis en place avant le retour : le cadre de
/// test l'exige avant la fin de l'essai.
Future<List<String>> collectOverflows(
  Future<void> Function() body, {
  bool ignoreOtherErrors = false,
}) async {
  final overflows = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('overflowed')) {
      overflows.add(message.split('\n').first);
    } else if (!ignoreOtherErrors) {
      previous?.call(details);
    }
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return overflows;
}

/// Avance le temps sans attendre la stabilité : un écran qui montre une roue
/// de chargement ne se stabilise jamais.
Future<void> pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Monte [child] comme dans l'application (thème clair, échelle de texte
/// C233) sur un écran de [size], et rend les débordements signalés.
///
/// [wrap] entoure l'application (fournisseurs).
Future<List<String>> pumpAtPhoneWidth(
  WidgetTester tester,
  Widget child, {
  Size size = phoneSize,
  Widget Function(Widget app)? wrap,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: PharmaConnectAppTheme.light(),
    builder: (context, page) => AdaptiveTextScale(child: page!),
    home: child,
  );
  return collectOverflows(() async {
    await tester.pumpWidget(wrap == null ? app : wrap(app));
    await pumpFrames(tester);
  });
}
