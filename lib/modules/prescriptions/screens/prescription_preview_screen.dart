import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../models/prescription_item.dart';
import '../providers/prescription_provider.dart';
import '../widgets/prescription_item_tile.dart';
import '../widgets/ocr_confidence_indicator.dart';

class PrescriptionPreviewScreen extends StatefulWidget {
  const PrescriptionPreviewScreen({super.key});

  @override
  State<PrescriptionPreviewScreen> createState() =>
      _PrescriptionPreviewScreenState();
}

class _PrescriptionPreviewScreenState extends State<PrescriptionPreviewScreen> {
  bool _isValidating = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final items = provider.extractedItems;
    final confidence = provider.ocrConfidenceScore;
    final availabilityMap = provider.availabilityMap;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () {
                    provider.resetUpload();
                    context.pop();
                  },
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Vérification de l\'ordonnance',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score de confiance OCR
                    Center(
                      child: OcrConfidenceIndicator(confidence: confidence),
                    ),
                    const SizedBox(height: 24),

                    // Liste des médicaments extraits
                    const Text(
                      'Médicaments détectés',
                      style: PharmaConnectTypography.heading3,
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty) ...[
                      const Text(
                        'Aucun médicament détecté',
                        style: PharmaConnectTypography.body2,
                      ),
                    ] else ...[
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return PrescriptionItemTile(
                          item: item,
                          isExtracted: true,
                          showActions: true,
                          isControlledSubstance:
                              provider.controlledSubstanceMap[item
                                  .medicationName] ??
                              false,
                          onEdit: () => _showEditDialog(context, index, item),
                          onSubstitute: item.hasGenericAlternative
                              ? () => _showSubstitutionDialog(
                                  context,
                                  index,
                                  item,
                                )
                              : null,
                        );
                      }),
                    ],
                    const SizedBox(height: 16),

                    // Disponibilité des produits
                    if (availabilityMap.isNotEmpty) ...[
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),
                      const Text(
                        'Disponibilité en pharmacie',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...availabilityMap.entries.map((entry) {
                        final isAvailable = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isAvailable
                                    ? Icons.check_circle
                                    : Icons.error_outline,
                                color: isAvailable
                                    ? PharmaConnectColors.accentGreen
                                    : PharmaConnectColors.accentRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: PharmaConnectTypography.body1,
                                ),
                              ),
                              Text(
                                isAvailable ? 'Disponible' : 'Rupture',
                                style: PharmaConnectTypography.body2.copyWith(
                                  color: isAvailable
                                      ? PharmaConnectColors.accentGreen
                                      : PharmaConnectColors.accentRed,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: TertiaryButton(
                            label: 'Retour',
                            onPressed: () {
                              provider.resetUpload();
                              context.pop();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            label: _isValidating
                                ? 'Validation en cours...'
                                : 'Valider l\'ordonnance',
                            isLoading: _isValidating,
                            onPressed: items.isEmpty
                                ? null
                                : () async {
                                    setState(() => _isValidating = true);
                                    final prescription =
                                        provider.selectedPrescription;
                                    if (prescription != null) {
                                      await provider.validatePrescription(
                                        prescription.id,
                                      );
                                      if (context.mounted) {
                                        context.go(
                                          '/prescriptions/${prescription.id}',
                                        );
                                      }
                                    }
                                    setState(() => _isValidating = false);
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, int index, PrescriptionItem item) {
    final controller = TextEditingController(text: item.medicationName);
    final dosageController = TextEditingController(text: item.dosage);
    final freqController = TextEditingController(text: item.frequency);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Modifier le médicament'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nom du médicament',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: freqController,
              decoration: const InputDecoration(
                labelText: 'Fréquence',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newItem = item.copyWith(
                medicationName: controller.text,
                dosage: dosageController.text,
                frequency: freqController.text,
              );
              context.read<PrescriptionProvider>().updateExtractedItem(
                index,
                newItem,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showSubstitutionDialog(
    BuildContext context,
    int index,
    PrescriptionItem item,
  ) {
    // Simuler des suggestions de substitution
    final suggestions = ['Générique A (500mg)', 'Générique B (500mg)'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Substitution générique'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Souhaitez-vous substituer "${item.medicationName}" par un générique ?',
              style: PharmaConnectTypography.body1,
            ),
            const SizedBox(height: 12),
            ...suggestions.map((suggestion) {
              return ListTile(
                title: Text(suggestion),
                onTap: () {
                  final newItem = item.copyWith(
                    medicationName: suggestion,
                    isSubstitutionAllowed: true,
                  );
                  context.read<PrescriptionProvider>().updateExtractedItem(
                    index,
                    newItem,
                  );
                  Navigator.pop(context);
                },
                leading: const Icon(
                  Icons.medication,
                  color: PharmaConnectColors.accentPurple,
                ),
                tileColor: Colors.white.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Garder l\'original'),
            ),
          ],
        ),
      ),
    );
  }
}
