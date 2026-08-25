import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/prescription_provider.dart';
import '../widgets/prescription_item_tile.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  final String prescriptionId;

  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionProvider>().loadPrescription(
        widget.prescriptionId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final prescription = provider.selectedPrescription;

    if (prescription == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Détail de l\'ordonnance',
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
                    // En-tête de l'ordonnance
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: prescription.statusColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ordonnance #${prescription.id}',
                                      style: PharmaConnectTypography.heading3,
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: prescription.statusColor
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            prescription.statusLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: prescription.statusColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(prescription.uploadedAt),
                                          style: PharmaConnectTypography.micro,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Patient',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      prescription.patientName,
                                      style: PharmaConnectTypography.body1,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Médecin',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      prescription.doctorName ??
                                          'Non renseigné',
                                      style: PharmaConnectTypography.body1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (prescription.ocrConfidenceScore != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Confiance OCR : ',
                                  style: PharmaConnectTypography.label,
                                ),
                                Text(
                                  '${(prescription.ocrConfidenceScore! * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        prescription.ocrConfidenceScore! > 0.8
                                        ? PharmaConnectColors.accentGreen
                                        : PharmaConnectColors.accentOrange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (prescription.notes != null) ...[
                            const SizedBox(height: 8),
                            Text('Notes : ${prescription.notes!}'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Médicaments
                    Text(
                      'Médicaments (${prescription.items.length})',
                      style: PharmaConnectTypography.heading3,
                    ),
                    const SizedBox(height: 8),
                    ...prescription.items.map((item) {
                      return PrescriptionItemTile(
                        item: item,
                        isExtracted: item.isExtractedByOcr,
                      );
                    }),
                    const SizedBox(height: 24),

                    // Actions (selon statut)
                    if (prescription.isPending) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Valider l\'ordonnance',
                              icon: Icons.check_circle,
                              onPressed: () async {
                                await provider.validatePrescription(
                                  prescription.id,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ordonnance validée avec succès',
                                      ),
                                      backgroundColor:
                                          PharmaConnectColors.accentGreen,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Dispenser',
                              icon: Icons.medication,
                              onPressed: prescription.isValidated
                                  ? () async {
                                      await provider.dispensePrescription(
                                        prescription.id,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Ordonnance dispensée',
                                            ),
                                            backgroundColor:
                                                PharmaConnectColors.accentCyan,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TertiaryButton(
                        label: 'Archiver',
                        onPressed: () async {
                          await provider.archivePrescription(prescription.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ordonnance archivée'),
                                backgroundColor:
                                    PharmaConnectColors.textSecondary,
                              ),
                            );
                            context.pop();
                          }
                        },
                      ),
                    ],

                    if (prescription.isValidated) ...[
                      PrimaryButton(
                        label: 'Dispenser',
                        icon: Icons.medication,
                        onPressed: () async {
                          await provider.dispensePrescription(prescription.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ordonnance dispensée'),
                                backgroundColor: PharmaConnectColors.accentCyan,
                              ),
                            );
                          }
                        },
                      ),
                    ],

                    if (prescription.isDispensed) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentGreen.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PharmaConnectColors.accentGreen.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: PharmaConnectColors.accentGreen,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ordonnance dispensée le ${_formatDateFull(prescription.dispensedAt!)}',
                                style: PharmaConnectTypography.body1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }

  String _formatDateFull(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
