import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/prescription_item.dart';

class PrescriptionItemTile extends StatelessWidget {
  final PrescriptionItem item;
  final bool isExtracted;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onSubstitute;
  // RG-ORD-02 (audit Module 5, 29/08/2026) : « Une ordonnance pour un
  // produit classé stupéfiant doit être conservée sous forme d'original
  // vérifiable et ne peut être honorée que par retrait physique en
  // officine. » Rien dans ce module ne rattachait une ligne d'ordonnance au
  // regulatory_class du produit (Module 3) — ce badge amorce la visibilité
  // pharmacien ; l'application effective (bloquer une livraison à domicile
  // pour cette ligne) reste à faire dans le module de livraison, une fois
  // ce module audité.
  final bool isControlledSubstance;

  const PrescriptionItemTile({
    super.key,
    required this.item,
    this.isExtracted = false,
    this.showActions = false,
    this.onEdit,
    this.onSubstitute,
    this.isControlledSubstance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
        border: Border.all(
          color: isExtracted
              ? PharmaConnectColors.accentCyan.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicateur de confiance OCR
          if (isExtracted) ...[
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: item.ocrConfidence > 0.8
                    ? PharmaConnectColors.accentGreen
                    : PharmaConnectColors.accentOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isExtracted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentCyan.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OCR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: PharmaConnectColors.accentCyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        item.medicationName,
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.dosage} • ${item.frequency} • ${item.duration}',
                  style: PharmaConnectTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.instructions != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.instructions!,
                    style: PharmaConnectTypography.micro,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (isControlledSubstance) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentRed.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: PharmaConnectColors.accentRed,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Stupéfiant — retrait en officine uniquement',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (item.hasGenericAlternative) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentPurple.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💡', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text(
                          'Générique disponible',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: PharmaConnectColors.accentPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Actions
          if (showActions) ...[
            Row(
              children: [
                if (onEdit != null) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: PharmaConnectColors.textSecondary,
                      size: 18,
                    ),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                ],
                if (onSubstitute != null) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.swap_horiz,
                      color: PharmaConnectColors.accentPurple,
                      size: 18,
                    ),
                    onPressed: onSubstitute,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
