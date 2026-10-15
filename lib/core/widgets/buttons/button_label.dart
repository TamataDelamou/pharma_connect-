import 'package:flutter/material.dart';

/// C268, C272 : libellé d'un bouton. Règle d'Achille (15/10/2026) : deux
/// lignes au plus, jamais coupé par « … », mots entiers ; il ne rétrécit que
/// si deux lignes ne suffisent pas. Un libellé qui tient sur une ligne garde
/// sa taille (et le bouton sa hauteur).
class ButtonLabel extends StatelessWidget {
  final String label;
  final TextStyle style;

  const ButtonLabel(this.label, {super.key, required this.style});

  static const int maxLines = 2;

  /// Taille minimale, en part de la taille demandée.
  static const double minScale = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mesuré avec le style réellement affiché (police du thème comprise).
        final effective = DefaultTextStyle.of(context).style.merge(style);
        final fontSize = effective.fontSize ?? 14;
        final scale = fittingScale(
          label,
          effective.copyWith(fontSize: fontSize),
          maxWidth: constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
        );
        return Text(
          label,
          maxLines: maxLines,
          textAlign: TextAlign.center,
          style: style.copyWith(fontSize: fontSize * scale),
        );
      },
    );
  }

  /// Plus grande échelle (1 au plus, par pas de 5 %) à laquelle [label]
  /// tient sur [maxLines] lignes de [maxWidth], sans mot coupé en deux.
  static double fittingScale(
    String label,
    TextStyle style, {
    required double maxWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    if (!maxWidth.isFinite) return 1;
    final words = label.split(RegExp(r'[ \t\n]+')).where((w) => w.isNotEmpty);
    for (var scale = 1.0; scale > minScale; scale -= 0.05) {
      final scaled = style.copyWith(fontSize: style.fontSize! * scale);
      final whole = TextPainter(
        text: TextSpan(text: label, style: scaled),
        maxLines: maxLines,
        textScaler: textScaler,
        textDirection: textDirection,
      )..layout(maxWidth: maxWidth);
      final fits =
          !whole.didExceedMaxLines &&
          words.every((word) {
            final painter = TextPainter(
              text: TextSpan(text: word, style: scaled),
              maxLines: 1,
              textScaler: textScaler,
              textDirection: textDirection,
            )..layout();
            final ok = painter.width <= maxWidth + 0.5;
            painter.dispose();
            return ok;
          });
      whole.dispose();
      if (fits) return scale;
    }
    return minScale;
  }
}
