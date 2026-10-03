import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../../recall/models/recall_severity.dart';
import '../providers/traceability_provider.dart';
import '../widgets/batch_status_chip.dart';
import '../widgets/movement_timeline.dart';

class BatchDetailScreen extends StatefulWidget {
  final String batchId;

  const BatchDetailScreen({super.key, required this.batchId});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TraceabilityProvider>().loadBatch(widget.batchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TraceabilityProvider>();
    final batch = provider.selectedBatch;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (batch == null) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // C233 : en-tête adaptable (actions sous le titre sur téléphone).
              HeaderRow(
                leading: Row(
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
                        'Détail du lot',
                        style: PharmaConnectTypography.heading2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: [const KernelBadge()],
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: Center(
                  child: Text(
                    'Lot introuvable',
                    style: PharmaConnectTypography.body2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Expanded(
                  child: Text(
                    'Détail du lot',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                if (_canDeclareRecall(context) && !batch.isRecalled) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Déclarer un rappel',
                    icon: const Icon(
                      Icons.warning_amber,
                      color: PharmaConnectColors.accentRed,
                    ),
                    onPressed: () => _showRecallDialog(context),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations produit
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      batch.productName,
                                      style: PharmaConnectTypography.heading3,
                                    ),
                                    Text(
                                      'Lot: ${batch.batchNumber}',
                                      style: PharmaConnectTypography.body2,
                                    ),
                                    Text(
                                      'SN: ${batch.serialNumber}',
                                      style: PharmaConnectTypography.micro,
                                    ),
                                  ],
                                ),
                              ),
                              BatchStatusChip(status: batch.status),
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
                                      'Fabricant',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(batch.manufacturer),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'GTIN',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(batch.gtin),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fabrication',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(_formatDate(batch.manufacturingDate)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Péremption',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      _formatDate(batch.expiryDate),
                                      style: TextStyle(
                                        color:
                                            batch.expiryDate.isBefore(
                                              DateTime.now(),
                                            )
                                            ? PharmaConnectColors.accentRed
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (batch.isRecalled) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: PharmaConnectColors.accentRed.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: PharmaConnectColors.accentRed
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning,
                                    color: PharmaConnectColors.accentRed,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'RAPPEL: ${batch.recallReason}',
                                      style: PharmaConnectTypography.body2
                                          .copyWith(
                                            color:
                                                PharmaConnectColors.accentRed,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mouvements
                    const Text(
                      'Historique des mouvements',
                      style: PharmaConnectTypography.heading3,
                    ),
                    const SizedBox(height: 8),
                    if (provider.movements.isEmpty) ...[
                      const Text(
                        'Aucun mouvement',
                        style: PharmaConnectTypography.body2,
                      ),
                    ] else ...[
                      MovementTimeline(movements: provider.movements),
                    ],

                    const SizedBox(height: 16),

                    // Chaîne du froid
                    if (provider.coldChainRecords.isNotEmpty) ...[
                      const Text(
                        'Chaîne du froid',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...provider.coldChainRecords.map(
                        (record) => Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: record.isBreach
                                  ? PharmaConnectColors.accentRed.withValues(
                                      alpha: 0.2,
                                    )
                                  : Colors.white.withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                record.isBreach
                                    ? Icons.error_outline
                                    : Icons.check_circle,
                                color: record.isBreach
                                    ? PharmaConnectColors.accentRed
                                    : PharmaConnectColors.accentGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${record.temperature}°C',
                                      style: PharmaConnectTypography.body1,
                                    ),
                                    Text(
                                      _formatDateTime(record.timestamp),
                                      style: PharmaConnectTypography.micro,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                record.status,
                                style: TextStyle(
                                  color: record.isBreach
                                      ? PharmaConnectColors.accentRed
                                      : PharmaConnectColors.accentGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
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

  // Correctif audit Module 12 (29/08/2026) : TraceabilityService.recallBatch
  // et .updateBatchStatus existaient déjà dans le code (provider inclus)
  // mais n'étaient appelés depuis AUCUN écran — code mort, même motif que
  // celui déjà documenté pour la navigation (registre, item D6). Réservé
  // aux mêmes rôles que la policy RLS d'écriture sur traceable_batches.
  bool _canDeclareRecall(BuildContext context) {
    final role = context.watch<AuthProvider>().effectiveRole;
    return role == UserRole.pharmacien ||
        role == UserRole.grossiste ||
        role == UserRole.regulateur;
  }

  // Correctif porteur du projet (29/08/2026, clôture Module 12) : ce
  // formulaire ne demandait qu'un motif texte, suffisant pour le seul flag
  // is_recalled construit initialement. Depuis l'unification avec le module
  // recall (pharmacovigilance, registre C41/D21), un vrai dossier de rappel
  // est créé — la sévérité et la quantité concernée en sont des champs de
  // premier ordre (classement Classe I/II/III, taux de récupération), d'où
  // leur ajout ici plutôt que de les laisser à des valeurs par défaut
  // silencieuses.
  Future<void> _showRecallDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    final quantityController = TextEditingController();
    final provider = context.read<TraceabilityProvider>();
    var severity = RecallSeverity.classII;
    var isPublic = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Déclarer un rappel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motif du rappel',
                    hintText: 'Ex: défaut de fabrication détecté sur ce lot',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RecallSeverity>(
                  initialValue: severity,
                  decoration: const InputDecoration(labelText: 'Sévérité'),
                  items: RecallSeverity.values
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => severity = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantité concernée (optionnel)',
                    hintText: 'Unités du lot couvertes par ce rappel',
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: isPublic,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Avis de rappel public (visible par tous les patients)',
                    style: PharmaConnectTypography.body2,
                  ),
                  onChanged: (value) {
                    setDialogState(() => isPublic = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Confirmer le rappel',
                style: TextStyle(color: PharmaConnectColors.accentRed),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (reasonController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez préciser le motif du rappel'),
            backgroundColor: PharmaConnectColors.accentRed,
          ),
        );
      }
      return;
    }

    // issuedBy : aucun libellé (nom complet) n'est exposé côté client par
    // AuthProvider aujourd'hui (voir auth_provider.dart) — même limite déjà
    // documentée pour verifiedBy dans verification_screen.dart. Le rôle
    // reste identifiant et cohérent avec la chaîne d'approvisionnement.
    final role = context.mounted
        ? context.read<AuthProvider>().effectiveRole
        : null;
    final totalUnits = int.tryParse(quantityController.text.trim()) ?? 0;

    final success = await provider.recallBatch(
      widget.batchId,
      reason: reasonController.text.trim(),
      issuedBy: role?.label ?? 'Utilisateur',
      severity: severity,
      totalUnits: totalUnits,
      isPublic: isPublic,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Rappel déclaré' : (provider.error ?? 'Échec du rappel'),
        ),
        backgroundColor: success
            ? PharmaConnectColors.accentGreen
            : PharmaConnectColors.accentRed,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
