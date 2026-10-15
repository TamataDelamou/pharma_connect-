import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';

import '../../helpers/phone_layout.dart';

// C268, C272 : libellé de bouton. Deux lignes au plus, jamais « … », mots
// entiers ; il ne rétrécit que si deux lignes ne suffisent pas ; sur une
// ligne, il garde sa taille et le bouton sa hauteur.

Future<RenderParagraph> _pump(
  WidgetTester tester,
  String label,
  double width,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PharmaConnectAppTheme.light(),
      home: Scaffold(
        body: Center(
          child: PrimaryButton(label: label, width: width, onPressed: () {}),
        ),
      ),
    ),
  );
  return tester.renderObject<RenderParagraph>(find.text(label));
}

double _fontSize(RenderParagraph p) => p.text.style!.fontSize!;

int _lines(RenderParagraph p) => p
    .getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
    )
    .map((b) => b.top)
    .toSet()
    .length;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('sur une ligne : taille et hauteur inchangées', (tester) async {
    final p = await _pump(tester, 'Rechercher', 300);
    expect(_fontSize(p), 16);
    expect(_lines(p), 1);
    expect(tester.getSize(find.byType(PrimaryButton)).height, 50);
  });

  testWidgets('trop long pour une ligne : deux lignes, même taille', (
    tester,
  ) async {
    final p = await _pump(tester, 'Vérifier la disponibilité', 170);
    expect(_fontSize(p), 16);
    expect(_lines(p), 2);
    expect(p.didExceedMaxLines, isFalse);
  });

  testWidgets('deux lignes ne suffisent pas : il rétrécit, rien de coupé', (
    tester,
  ) async {
    final p = await _pump(tester, 'Vérifier la disponibilité', 110);
    expect(_fontSize(p), lessThan(16));
    expect(p.didExceedMaxLines, isFalse);
    expect(brokenWords(tester), isEmpty);
  });
}
