import 'package:flutter/material.dart';
import '../text/whole_words_text.dart';

import '../../theme/palette.dart';
import '../layout/responsive.dart';
import 'glass_card.dart';

/// C265 : une tuile de chiffre (titre, valeur, détail facultatif).
class StatTileData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? detail;
  final VoidCallback? onTap;

  const StatTileData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.detail,
    this.onTap,
  });
}

/// C265 : rangée de tuiles de chiffres, commune aux écrans du pilote.
/// - Large : toutes les tuiles côte à côte.
/// - Téléphone : grille de deux colonnes. Côte à côte, quatre tuiles ne
///   laissaient à 360 px qu'une quarantaine de pixels au titre, coupé à
///   « … ».
///
/// Le titre est toujours écrit en entier (sur deux lignes au besoin) et
/// chaque tuile n'a qu'une icône : pas d'émoji dans le titre.
class StatTileGrid extends StatelessWidget {
  final List<StatTileData> tiles;

  const StatTileGrid({super.key, required this.tiles});

  static const double _gap = 12;

  /// Marge intérieure, icône et espace avant le titre.
  static const double _padding = 12;
  static const double _iconWidth = 18 + 6;

  @override
  Widget build(BuildContext context) {
    final perRow = isCompactWidth(context) ? 2 : tiles.length;
    // C276 : un mot du titre n'est jamais coupé au milieu : le titre passe
    // à la ligne entre les mots et ne rétrécit que si son mot le plus long
    // ne tient pas. Mesuré ici, au-dessus de IntrinsicHeight, qui interdit
    // les mesures dans la tuile elle-même. Même taille pour toutes les
    // tuiles.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - _gap * (perRow - 1)) / perRow;
        final labelWidth = tileWidth - 2 * _padding - _iconWidth - 2;
        final labelStyle = DefaultTextStyle.of(
          context,
        ).style.merge(context.text.label);
        var labelScale = 1.0;
        for (final tile in tiles) {
          final scale = WholeWordsText.longestWordScale(
            tile.label,
            labelStyle,
            maxWidth: labelWidth,
            textScaler: MediaQuery.textScalerOf(context),
            textDirection: Directionality.of(context),
          );
          if (scale < labelScale) labelScale = scale;
        }
        return _rows(perRow, labelScale);
      },
    );
  }

  Widget _rows(int perRow, double labelScale) {
    final rows = <Widget>[];
    for (var start = 0; start < tiles.length; start += perRow) {
      final row = tiles.skip(start).take(perRow).toList();
      if (rows.isNotEmpty) rows.add(const SizedBox(height: _gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < perRow; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                Expanded(
                  child: i < row.length
                      ? _StatTile(tile: row[i], labelScale: labelScale)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

class _StatTile extends StatelessWidget {
  final StatTileData tile;

  /// C276 : échelle du titre, calculée par la grille.
  final double labelScale;

  const _StatTile({required this.tile, this.labelScale = 1});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: tile.onTap,
      padding: const EdgeInsets.all(StatTileGrid._padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(tile.icon, color: tile.color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tile.label,
                  style: labelScale == 1
                      ? context.text.label
                      : context.text.label.copyWith(
                          fontSize:
                              (context.text.label.fontSize ?? 12) * labelScale,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              tile.value,
              style: context.text.kpiMedium.copyWith(
                color: tile.color,
                fontSize: 24,
              ),
            ),
          ),
          if (tile.detail != null)
            Text(tile.detail!, style: context.text.micro),
        ],
      ),
    );
  }
}
