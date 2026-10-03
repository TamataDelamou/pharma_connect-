import 'package:flutter/material.dart';

import '../../theme/typography.dart';

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
  final TextStyle style;
  final List<Widget> actions;

  const ResponsiveHeader({
    super.key,
    required this.title,
    this.style = PharmaConnectTypography.heading2,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      style: style,
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
