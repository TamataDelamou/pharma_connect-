import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/pilot/pilot_config.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/prescription_provider.dart';
import '../widgets/prescription_item_tile.dart';
import '../../../core/theme/palette.dart';

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
    // Bug corrigé (audit Module 5, 29/08/2026) — RG-ORD-01 : « Aucune
    // extraction automatique issue de l'OCR/IA ne peut déclencher une
    // dispensation sans validation explicite d'un pharmacien habilité. »
    // Cet écran affichait les boutons Valider/Dispenser/Archiver à
    // N'IMPORTE QUEL utilisateur consultant l'ordonnance — y compris le
    // patient lui-même (prescriptions_select_own l'y autorise), qui pouvait
    // donc valider et dispenser sa propre ordonnance sans aucune
    // intervention pharmacien. Aucune vérification de rôle n'existait, ni
    // ici ni côté serveur (prescriptions n'avait même pas de policy UPDATE
    // avant ce module — voir la migration 20260829016000). Corrigé sur les
    // deux plans : RLS (prescriptions_staff_update, is_pharmacist()) et ici,
    // en défense en profondeur, sur le même modèle que le bouton "Gérer le
    // stock" gated en Module 3 (catalog_detail_screen.dart).
    final isPharmacist =
        context.watch<AuthProvider>().effectiveRole == UserRole.pharmacien;

    if (prescription == null && provider.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  provider.error!,
                  style: context.text.body2.copyWith(
                    color: context.palette.danger,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context
                    .read<PrescriptionProvider>()
                    .loadPrescription(widget.prescriptionId),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

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
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Détail de l\'ordonnance',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            if (provider.isOffline) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.palette.warningStrong.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.palette.warningStrong.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 18,
                      color: context.palette.warningStrong,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error ??
                            'Hors-ligne — dernière version connue.',
                        style: context.text.micro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                                  color: prescription.statusColor.of(
                                    context.palette,
                                  ),
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
                                      style: context.text.heading3,
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
                                                .of(context.palette)
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
                                              color: prescription.statusColor
                                                  .of(context.palette),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(prescription.uploadedAt),
                                          style: context.text.micro,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(color: context.palette.veil(0.12)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Patient', style: context.text.label),
                                    Text(
                                      prescription.patientName,
                                      style: context.text.body1,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Médecin', style: context.text.label),
                                    Text(
                                      prescription.doctorName ??
                                          'Non renseigné',
                                      style: context.text.body1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // C239 : score masqué pour le pilote.
                          if (PilotConfig.aiPrescriptionOcr &&
                              prescription.ocrConfidenceScore != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Confiance OCR : ',
                                  style: context.text.label,
                                ),
                                Text(
                                  '${(prescription.ocrConfidenceScore! * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        prescription.ocrConfidenceScore! > 0.8
                                        ? context.palette.success
                                        : context.palette.warning,
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
                      style: context.text.heading3,
                    ),
                    const SizedBox(height: 8),
                    ...prescription.items.map((item) {
                      return PrescriptionItemTile(
                        item: item,
                        isExtracted: item.isExtractedByOcr,
                      );
                    }),
                    const SizedBox(height: 24),

                    // Actions (selon statut ET rôle — RG-ORD-01, voir plus
                    // haut). Un patient (ou tout compte non-pharmacien) ne
                    // voit plus jamais Valider/Dispenser/Archiver : seulement
                    // un rappel du statut, en lecture seule.
                    if (prescription.isPending) ...[
                      if (isPharmacist) ...[
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
                                      SnackBar(
                                        content: Text(
                                          'Ordonnance validée avec succès',
                                        ),
                                        backgroundColor:
                                            context.palette.success,
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
                                            SnackBar(
                                              content: Text(
                                                'Ordonnance dispensée',
                                              ),
                                              backgroundColor:
                                                  context.palette.primary,
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
                                SnackBar(
                                  content: Text('Ordonnance archivée'),
                                  backgroundColor:
                                      context.palette.textSecondary,
                                ),
                              );
                              context.pop();
                            }
                          },
                        ),
                      ] else ...[
                        _StatusNotice(
                          icon: Icons.hourglass_top,
                          color: context.palette.warning,
                          text:
                              'En attente de validation par un pharmacien habilité.',
                        ),
                      ],
                    ],

                    if (prescription.isValidated) ...[
                      if (isPharmacist) ...[
                        PrimaryButton(
                          label: 'Dispenser',
                          icon: Icons.medication,
                          onPressed: () async {
                            await provider.dispensePrescription(
                              prescription.id,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ordonnance dispensée'),
                                  backgroundColor: context.palette.primary,
                                ),
                              );
                            }
                          },
                        ),
                      ] else ...[
                        _StatusNotice(
                          icon: Icons.check_circle_outline,
                          color: context.palette.success,
                          text:
                              'Validée par un pharmacien — à retirer en officine.',
                        ),
                      ],
                    ],

                    if (prescription.isDispensed) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.palette.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.palette.success.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: context.palette.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ordonnance dispensée le ${_formatDateFull(prescription.dispensedAt!)}',
                                style: context.text.body1,
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

/// Rappel de statut en lecture seule pour un patient consultant sa propre
/// ordonnance en attente/validée — RG-ORD-01 (audit Module 5, 29/08/2026).
class _StatusNotice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StatusNotice({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: context.text.body1.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
