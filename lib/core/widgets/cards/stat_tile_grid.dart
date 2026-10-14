import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final perRow = isCompactWidth(context) ? 2 : tiles.length;
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
                      ? _StatTile(tile: row[i])
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

  const _StatTile({required this.tile});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: tile.onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(tile.icon, color: tile.color, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(tile.label, style: context.text.label)),
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
