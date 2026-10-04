// C234 : planches-contacts de toutes les routes sans paramètre, à 360 px de
// large, en thème clair, et contrôle automatique du contraste des textes.
//
//   flutter test tool/screenshots/c234_contact_sheets_test.dart
//
// Sorties dans build/c234_screenshots/planches/ (non versionné) :
//   - planche_NN.png : 12 écrans par image, la route sous chaque écran ;
//   - contraste.txt : textes et icônes dont le contraste mesuré avec le fond
//     est inférieur à 3:1 ;
//   - a_verifier/ : capture pleine taille de chaque écran signalé ;
//   - pleine_taille/ : capture pleine taille de quelques écrans de référence ;
//   - routes.txt : routes capturées et routes à paramètre non capturées.
//
// Les écrans sont montés hors ligne, avec les routes réelles : données vides
// ou en erreur réseau. Seul le rendu des couleurs est contrôlé.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/app.dart';
import 'package:pharma_connect/core/theme/adaptive_text_scale.dart';
import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/modules/auth/models/user_role.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/routes/app_router.dart';

const _outputDir = 'build/c234_screenshots/planches';
const _size = Size(360, 780);
const _columns = 6;
const _rows = 2;
const _gap = 16.0;
const _labelHeight = 44.0;

/// Écrans dont la capture pleine taille est toujours écrite (pleine_taille/).
const _fullSizeRoutes = {'/scan', '/healthrecord', '/stock', '/payments'};

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Chemins complets des routes, séparés en routes sans et avec paramètre.
void _collect(
  List<RouteBase> routes,
  String parent,
  List<String> plain,
  List<String> withParams,
) {
  for (final route in routes) {
    var path = parent;
    if (route is GoRoute) {
      path = route.path.startsWith('/')
          ? route.path
          : '${parent == '/' ? '' : parent}/${route.path}';
      // Une route de pure redirection n'a pas d'écran.
      if (route.builder != null || route.pageBuilder != null) {
        (path.contains(':') ? withParams : plain).add(path);
      }
    }
    _collect(route.routes, path, plain, withParams);
  }
}

double _luminance(int r, int g, int b) {
  double channel(int v) {
    final c = v / 255;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

class _Capture {
  final String route;
  final ui.Image image;
  final int issues;
  _Capture(this.route, this.image, this.issues);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
    const inter = 'assets/fonts/Inter';
    await _loadFont('Inter', [
      '$inter/Inter-Regular.ttf',
      '$inter/Inter-Medium.ttf',
      '$inter/Inter-SemiBold.ttf',
      '$inter/Inter-Bold.ttf',
    ]);
    await _loadFont('JetBrainsMono', [
      'assets/fonts/JetBrainsMono/JetBrainsMono-Light.ttf',
    ]);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      await _loadFont('MaterialIcons', [
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
            'MaterialIcons-Regular.otf',
      ]);
    }
    final dir = Directory(_outputDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    Directory('$_outputDir/a_verifier').createSync();
    Directory('$_outputDir/pleine_taille').createSync();
  });

  testWidgets(
    'planches-contacts et contraste, toutes les routes sans paramètre',
    (tester) async {
      tester.view.physicalSize = _size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      debugDisableShadows = false;
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (_) {};

      final plain = <String>[];
      final withParams = <String>[];
      _collect(AppRouter.router.configuration.routes, '', plain, withParams);

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: AppRouter.router.configuration.routes,
      );
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MultiProvider(
            providers: appProviders(restoreSession: false),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: PharmaConnectAppTheme.light(),
              routerConfig: router,
              builder: (context, child) => AdaptiveTextScale(child: child!),
            ),
          ),
        ),
      );
      // Compte pharmacien rattaché à une officine : les écrans d'officine
      // affichent leur contenu plutôt qu'un message « aucune officine ».
      final auth = tester
          .element(find.byType(AdaptiveTextScale))
          .read<AuthProvider>();
      auth.setRole(UserRole.pharmacien);
      auth.pharmacyIdForTesting = '00000000-0000-0000-0000-000000000001';

      final captures = <_Capture>[];
      final contrastLines = <String>[];
      final failed = <String>[];

      for (final route in plain) {
        try {
          router.go(route);
          // Animations en boucle (indicateur Kernel) : pas de pumpAndSettle.
          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 150));
          }
        } catch (error) {
          failed.add('$route : $error');
          continue;
        }

        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        late ui.Image image;
        late Uint8List rgba;
        await tester.runAsync(() async {
          image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData();
          rgba = data!.buffer.asUint8List();
        });
        final width = image.width, height = image.height;

        // Contraste de chaque texte (et icône) visible avec le fond relevé
        // aux quatre coins de sa boîte.
        var issues = 0;
        final seen = <String>{};
        for (final element in find.byType(RichText).evaluate()) {
          final widget = element.widget as RichText;
          final renderObject = element.renderObject;
          if (renderObject is! RenderBox ||
              !renderObject.attached ||
              !renderObject.hasSize) {
            continue;
          }
          Color? color;
          widget.text.visitChildren((span) {
            color ??= span.style?.color;
            return color == null;
          });
          final label = widget.text.toPlainText().trim();
          if (color == null || label.isEmpty) continue;
          final origin = renderObject.localToGlobal(Offset.zero);
          final box = origin & renderObject.size;
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
            final alpha = color!.a;
            final r = (color!.r * 255 * alpha + br * (1 - alpha)).round();
            final g = (color!.g * 255 * alpha + bg * (1 - alpha)).round();
            final b = (color!.b * 255 * alpha + bb * (1 - alpha)).round();
            final l1 = _luminance(r, g, b), l2 = _luminance(br, bg, bb);
            samples.add((math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05));
          }
          samples.sort();
          // Médiane basse : un seul coin posé sur autre chose ne suffit pas.
          final contrast = samples[1];
          if (contrast < 3) {
            final isIcon = label.runes.every((rune) => rune >= 0xE000);
            final shown = isIcon ? '(icône)' : label.replaceAll('\n', ' ');
            final text = shown.length > 50 ? shown.substring(0, 50) : shown;
            final hex = color!
                .toARGB32()
                .toRadixString(16)
                .padLeft(8, '0')
                .toUpperCase();
            final line =
                '$route | ${contrast.toStringAsFixed(2)}:1 | #$hex | $text';
            if (seen.add(line)) {
              contrastLines.add(line);
              issues++;
            }
          }
        }
        if (issues > 0) {
          // Capture pleine taille des écrans signalés, pour les relire.
          await tester.runAsync(() async {
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final name = route.replaceAll('/', '_');
            File(
              '$_outputDir/a_verifier/$name.png',
            ).writeAsBytesSync(png!.buffer.asUint8List());
          });
        }
        if (_fullSizeRoutes.contains(route)) {
          await tester.runAsync(() async {
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final name = route.replaceAll('/', '_');
            File(
              '$_outputDir/pleine_taille/$name.png',
            ).writeAsBytesSync(png!.buffer.asUint8List());
          });
        }
        captures.add(_Capture(route, image, issues));
      }

      // ==================== PLANCHES ====================
      const perSheet = _columns * _rows;
      final sheetWidth = _columns * (_size.width + _gap) + _gap;
      final sheetHeight = _rows * (_size.height + _labelHeight + _gap) + _gap;
      await tester.runAsync(() async {
        for (var start = 0; start < captures.length; start += perSheet) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawRect(
            Rect.fromLTWH(0, 0, sheetWidth, sheetHeight),
            Paint()..color = const Color(0xFF3A3F4B),
          );
          final end = math.min(start + perSheet, captures.length);
          for (var i = start; i < end; i++) {
            final capture = captures[i];
            final column = (i - start) % _columns,
                row = (i - start) ~/ _columns;
            final x = _gap + column * (_size.width + _gap);
            final y = _gap + row * (_size.height + _labelHeight + _gap);
            canvas.drawImage(capture.image, Offset(x, y), Paint());
            final builder =
                ui.ParagraphBuilder(
                    ui.ParagraphStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      maxLines: 2,
                      ellipsis: '…',
                    ),
                  )
                  ..pushStyle(
                    ui.TextStyle(
                      color: capture.issues > 0
                          ? const Color(0xFFFFB4A8)
                          : const Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                  ..addText(
                    capture.issues > 0
                        ? '${capture.route}  [contraste : ${capture.issues}]'
                        : capture.route,
                  );
            final paragraph = builder.build()
              ..layout(ui.ParagraphConstraints(width: _size.width));
            canvas.drawParagraph(paragraph, Offset(x, y + _size.height + 4));
          }
          final sheet = await recorder.endRecording().toImage(
            sheetWidth.round(),
            sheetHeight.round(),
          );
          final data = await sheet.toByteData(format: ui.ImageByteFormat.png);
          final number = (start ~/ perSheet + 1).toString().padLeft(2, '0');
          File(
            '$_outputDir/planche_$number.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
        }
      });

      File('$_outputDir/contraste.txt').writeAsStringSync(
        [
          'Textes et icônes dont le contraste mesuré est inférieur à 3:1 '
              '(${contrastLines.length})',
          'route | contraste | couleur du texte (ARGB) | texte',
          '',
          ...contrastLines,
        ].join('\n'),
      );
      File('$_outputDir/routes.txt').writeAsStringSync(
        [
          'Routes capturées (${captures.length})',
          for (var i = 0; i < captures.length; i++)
            'planche_${(i ~/ perSheet + 1).toString().padLeft(2, '0')} | '
                '${captures[i].route}',
          '',
          'Routes à paramètre, non capturées (${withParams.length})',
          ...withParams,
          if (failed.isNotEmpty) ...['', 'Routes en échec', ...failed],
        ].join('\n'),
      );

      // Les erreurs réseau tardives des écrans sont encore ignorées pendant
      // le démontage.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(minutes: 5));
      FlutterError.onError = previousOnError;
      debugDisableShadows = true;
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
