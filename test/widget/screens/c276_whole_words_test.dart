import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:pharma_connect/core/widgets/text/whole_words_text.dart';

import '../../helpers/phone_layout.dart';

// C276 : un mot n'est jamais coupé au milieu : passage à la ligne entre les
// mots, rétrécissement seulement si le mot le plus long ne tient pas. Un
// montant passe seul sur sa ligne, en entier. Le nom de l'application tient
// sur une ligne.

Future<void> _pump(WidgetTester tester, double width, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PharmaConnectAppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

double _fontSize(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!.fontSize!;

int _lines(WidgetTester tester, String text) => tester
    .renderObject<RenderParagraph>(find.text(text))
    .getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    )
    .map((b) => b.top)
    .toSet()
    .length;

void main() {
  setUpAll(loadAppFonts);

  const style = TextStyle(fontSize: 16);

  testWidgets('les mots tiennent : taille inchangée, passage à la ligne', (
    tester,
  ) async {
    const text = 'Pharmacie Centrale de la Minière';
    await _pump(tester, 120, const WholeWordsText(text, style: style));
    expect(_fontSize(tester, text), 16);
    expect(_lines(tester, text), greaterThan(1));
    expect(brokenWords(tester), isEmpty);
  });

  testWidgets('un mot trop long : il rétrécit, sans être coupé', (
    tester,
  ) async {
    const text = 'Lot #LOT-2025-AMX-000987';
    await _pump(tester, 110, const WholeWordsText(text, style: style));
    expect(_fontSize(tester, text), lessThan(16));
    expect(brokenWords(tester), isEmpty);
  });

  testWidgets('un montant passe seul sur sa ligne, en entier', (tester) async {
    final text = '1 article(s) • ${CurrencyFormatter.format(1500000)}';
    await _pump(tester, 130, WholeWordsText(text, style: style));
    expect(_fontSize(tester, text), 16);
    expect(_lines(tester, text), 2);
    expect(brokenWords(tester), isEmpty);
  });

  testWidgets('nom de l\'application : une ligne, rétréci si besoin', (
    tester,
  ) async {
    await _pump(tester, 90, const AppNameText(style: TextStyle(fontSize: 18)));
    expect(_lines(tester, AppNameText.name), 1);
    expect(
      tester.getSize(find.text(AppNameText.name)).width,
      greaterThan(90),
      reason: 'texte posé en entier, puis réduit par FittedBox',
    );
    expect(
      tester.getSize(find.byType(AppNameText)).width,
      lessThanOrEqualTo(90),
    );
  });
}
