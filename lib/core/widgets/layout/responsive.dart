import 'package:flutter/material.dart';

import '../../theme/typography.dart';
import '../../theme/palette.dart';

/// C233 : vrai en largeur téléphone (même seuil que l'échelle de texte).
bool isCompactWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width <
    PharmaConnectTypography.compactBreakpoint;

/// C233 : marge extérieure d'un écran, réduite en largeur téléphone.
EdgeInsets screenPadding(BuildContext context, {double wide = 32}) =>
    EdgeInsets.all(isCompactWidth(context) ? 16 : wide);

/// C233 : en-tête d'écran (titre et actions).
/// - Large : titre à gauche, actions à droite, sur une ligne.
/// - Téléphone : titre sur toute la largeur (2 lignes au plus, coupé avec
///   « … »), actions en dessous, qui passent à la ligne si besoin.
/// Remplace le gabarit `Row[Expanded(titre), badge, bouton]`, qui ne laissait
/// presque plus de place au titre à 360 px.
class ResponsiveHeader extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final List<Widget> actions;

  const ResponsiveHeader({
    super.key,
    required this.title,
    this.style,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      style: style ?? context.text.heading2,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    if (!isCompactWidth(context)) {
      return Row(
        children: [
          Expanded(child: titleText),
          for (final action in actions) ...[const SizedBox(width: 16), action],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleText,
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        ],
      ],
    );
  }
}

/// C233 : en-tête d'écran avec un bloc de titre libre ([leading] : titre,
/// sous-titre, bouton retour…) et des actions ([trailing] : badge, boutons).
/// - Large : `Row[Expanded(leading), actions…]`, comme avant.
/// - Téléphone : le bloc de titre prend toute la largeur, les actions passent
///   en dessous et à la ligne si besoin.
class HeaderRow extends StatelessWidget {
  final Widget leading;
  final List<Widget> trailing;

  const HeaderRow({super.key, required this.leading, this.trailing = const []});

  @override
  Widget build(BuildContext context) {
    if (!isCompactWidth(context)) {
      return Row(
        children: [
          Expanded(child: leading),
          for (final action in trailing) ...[const SizedBox(width: 16), action],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        if (trailing.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: trailing,
          ),
        ],
      ],
    );
  }
}

/// C253 : rangée de boutons d'action.
/// - Large : côte à côte, chacun selon son poids ([flex], 1 par défaut).
/// - Téléphone : l'un sous l'autre, sur toute la largeur. Côte à côte, il ne
///   restait à 360 px qu'une cinquantaine de pixels par libellé : le texte
///   débordait, ou aurait été coupé. Un libellé doit se lire en entier.
class ResponsiveActions extends StatelessWidget {
  final List<Widget> children;
  final List<int>? flex;

  const ResponsiveActions({super.key, required this.children, this.flex});

  @override
  Widget build(BuildContext context) {
    if (!isCompactWidth(context)) {
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(flex: flex?[i] ?? 1, child: children[i]),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
      ],
    );
  }
}
