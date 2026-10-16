import 'package:flutter/material.dart';

/// C276 : règle d'Achille (16/10/2026) : un mot n'est jamais coupé au milieu.
/// Le texte passe à la ligne entre les mots ; il ne rétrécit que si le mot le
/// plus long ne tient pas sur la largeur disponible.
///
/// Un montant écrit par `CurrencyFormatter` (« 1 500 000 GNF », espaces
/// insécables) compte pour un seul mot : s'il ne tient pas sur la ligne, il
/// passe seul sur la suivante, en entier, et ne rétrécit qu'en dernier
/// recours.
class WholeWordsText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const WholeWordsText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  /// Taille minimale, en part de la taille demandée.
  static const double minScale = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mesuré avec le style réellement affiché (police du thème comprise).
        final effective = DefaultTextStyle.of(context).style.merge(style);
        final fontSize = effective.fontSize ?? 14;
        final scale = longestWordScale(
          data,
          effective,
          maxWidth: constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
        );
        return Text(
          data,
          style: scale == 1
              ? style
              : (style ?? const TextStyle()).copyWith(
                  fontSize: fontSize * scale,
                ),
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }

  /// Plus grande échelle (1 au plus) à laquelle le mot le plus long de [text]
  /// tient sur [maxWidth]. Les mots sont séparés par les espaces ordinaires
  /// seulement : un montant à espaces insécables reste d'un seul tenant.
  static double longestWordScale(
    String text,
    TextStyle style, {
    required double maxWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    if (!maxWidth.isFinite) return 1;
    final words = text.split(RegExp(r'[ \t\n]+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return 1;
    final fontSize = style.fontSize ?? 14;
    double widest(double scale) {
      var max = 0.0;
      final scaled = style.copyWith(fontSize: fontSize * scale);
      for (final word in words) {
        final painter = TextPainter(
          text: TextSpan(text: word, style: scaled),
          maxLines: 1,
          textScaler: textScaler,
          textDirection: textDirection,
        )..layout();
        if (painter.width > max) max = painter.width;
        painter.dispose();
      }
      return max;
    }

    if (widest(1) <= maxWidth + 0.5) return 1;
    for (var scale = 0.95; scale > minScale; scale -= 0.05) {
      if (widest(scale) <= maxWidth + 0.5) return scale;
    }
    return minScale;
  }
}

/// C276 : nom de l'application : toujours sur une seule ligne ; il rétrécit
/// si la place manque (écran étroit, police agrandie, zoom de l'écran).
class AppNameText extends StatelessWidget {
  final TextStyle? style;
  final AlignmentGeometry alignment;

  const AppNameText({
    super.key,
    this.style,
    this.alignment = AlignmentDirectional.centerStart,
  });

  static const String name = 'PHARMACONNECT';

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(name, maxLines: 1, softWrap: false, style: style),
    );
  }
}
