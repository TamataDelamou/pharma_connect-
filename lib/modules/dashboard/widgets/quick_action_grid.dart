import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/layout/responsive.dart';
import '../models/dashboard_data.dart';
import '../../../core/theme/palette.dart';

class QuickActionGrid extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    // C233 : 2 colonnes en largeur téléphone (4 cartes de 60 px sinon).
    final compact = isCompactWidth(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: compact ? 12 : 16,
        mainAxisSpacing: compact ? 12 : 16,
        childAspectRatio: compact ? 1.5 : 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GlassCard(
          padding: const EdgeInsets.all(12),
          onTap: () => context.go(action.route),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                color: context.palette.resolve(action.color),
                size: 32,
              ),
              const SizedBox(height: 8),
              // Flexible : un libellé sur deux lignes ne déborde pas de la
              // carte (petit écran, grande taille de texte).
              Flexible(
                child: Text(
                  action.label,
                  style: context.text.body2.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
