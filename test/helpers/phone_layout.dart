import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    await tester.pumpWidget(
      RepaintBoundary(
        key: phoneBoundaryKey,
        child: wrap == null ? app : wrap(app),
      ),
    );
    await pumpFrames(tester);
  });
}

// ==================== LISIBILITÉ (C265) ====================

/// Racine des écrans montés par [pumpAtPhoneWidth] : sert à relever les
/// couleurs réellement affichées.
final GlobalKey phoneBoundaryKey = GlobalKey();

/// C265 : textes coupés par « … » (ou effacés par un fondu) à l'écran. Un
/// titre réduit à « … » ne déborde pas : il disparaît.
List<String> truncatedTexts(WidgetTester tester) {
  final found = <String>{};
  for (final element in find.byType(RichText).evaluate()) {
    final render = element.renderObject;
    if (render is! RenderParagraph || !render.attached || !render.hasSize) {
      continue;
    }
    if (render.overflow == TextOverflow.visible ||
        render.overflow == TextOverflow.clip) {
      continue;
    }
    if (!render.didExceedMaxLines) continue;
    final text = render.text.toPlainText().replaceAll('\n', ' ').trim();
    if (text.isEmpty) continue;
    found.add(text.length > 60 ? '${text.substring(0, 60)}…' : text);
  }
  return found.toList();
}

double _luminance(int r, int g, int b) {
  double channel(int c) {
    final v = c / 255;
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

/// C265 : textes et icônes dont le contraste avec le fond est sous le seuil
/// fixé par Achille (13/10/2026) : 4,5:1 pour le texte courant, 3:1 pour les
/// gros textes (24 px, ou 18,66 px en gras) et les icônes. Le fond est relevé
/// aux quatre coins de chaque texte, sur l'image réellement affichée (même
/// méthode que tool/screenshots/c234_contact_sheets_test.dart).
Future<List<String>> lowContrastTexts(WidgetTester tester) async {
  final boundary =
      phoneBoundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
  late ui.Image image;
  late Uint8List rgba;
  await tester.runAsync(() async {
    image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData();
    rgba = data!.buffer.asUint8List();
  });
  final width = image.width, height = image.height;
  final found = <String>{};
  for (final element in find.byType(RichText).evaluate()) {
    final widget = element.widget as RichText;
    final render = element.renderObject;
    if (render is! RenderBox || !render.attached || !render.hasSize) continue;
    TextStyle? style;
    widget.text.visitChildren((span) {
      style ??= span.style?.color == null ? null : span.style;
      return style == null;
    });
    final color = style?.color;
    final label = widget.text.toPlainText().trim();
    if (color == null || label.isEmpty) continue;
    final origin = render.localToGlobal(Offset.zero);
    final box = origin & render.size;
    if (box.width < 4 ||
        box.height < 4 ||
        box.left < 0 ||
        box.top < 0 ||
        box.right > width ||
        box.bottom > height) {
      continue;
    }
    final samples = <double>[];
    for (final point in [
      box.topLeft + const Offset(1, 1),
      box.topRight + const Offset(-2, 1),
      box.bottomLeft + const Offset(1, -2),
      box.bottomRight + const Offset(-2, -2),
    ]) {
      final index = (point.dy.floor() * width + point.dx.floor()) * 4;
      final br = rgba[index], bg = rgba[index + 1], bb = rgba[index + 2];
      final alpha = color.a;
      final r = (color.r * 255 * alpha + br * (1 - alpha)).round();
      final g = (color.g * 255 * alpha + bg * (1 - alpha)).round();
      final b = (color.b * 255 * alpha + bb * (1 - alpha)).round();
      final l1 = _luminance(r, g, b), l2 = _luminance(br, bg, bb);
      samples.add((math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05));
    }
    samples.sort();
    // Médiane basse : un seul coin posé sur autre chose ne suffit pas.
    final contrast = samples[1];
    final isIcon = label.runes.every((rune) => rune >= 0xE000);
    final size =
        (style?.fontSize ?? 14) * MediaQuery.textScalerOf(element).scale(1);
    final bold = (style?.fontWeight?.value ?? 400) >= 600;
    final large = size >= 24 || (bold && size >= 18.66);
    final threshold = isIcon || large ? 3.0 : 4.5;
    if (contrast < threshold) {
      final shown = isIcon ? '(icône)' : label.replaceAll('\n', ' ');
      final text = shown.length > 50 ? '${shown.substring(0, 50)}…' : shown;
      final hex = color
          .toARGB32()
          .toRadixString(16)
          .padLeft(8, '0')
          .toUpperCase();
      found.add(
        '${contrast.toStringAsFixed(2)}:1 (seuil ${threshold.toStringAsFixed(1)}) | #$hex | $text',
      );
    }
  }
  return found.toList();
}

/// C265, découverte : relève les textes coupés et les contrastes faibles de
/// l'écran affiché et les ajoute à build/c265_decouverte.txt. N'échoue pas :
/// la liste est rendue à Achille avant toute correction.
Future<void> recordReadability(WidgetTester tester, String screen) async {
  final truncated = truncatedTexts(tester);
  final contrast = await lowContrastTexts(tester);
  final out = File('build/c265_decouverte.txt');
  out.parent.createSync(recursive: true);
  final lines = [
    for (final t in truncated) '$screen | coupé | $t',
    for (final c in contrast) '$screen | contraste | $c',
  ];
  if (lines.isNotEmpty) {
    out.writeAsStringSync('${lines.join('\n')}\n', mode: FileMode.append);
  }
}
