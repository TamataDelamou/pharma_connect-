import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_role.dart';
import '../providers/eprescription_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class EPrescriptionDetailScreen extends StatefulWidget {
  final String prescriptionId;

  const EPrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  State<EPrescriptionDetailScreen> createState() =>
      _EPrescriptionDetailScreenState();
}

class _EPrescriptionDetailScreenState extends State<EPrescriptionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EPrescriptionProvider>().loadPrescription(
        widget.prescriptionId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EPrescriptionProvider>();
    final prescription = provider.selectedPrescription;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (prescription == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Prescription introuvable',
            style: context.text.body2.copyWith(color: context.palette.danger),
          ),
        ),
      );
    }

    final isDoctor = prescription.doctorId == SupabaseService().currentUser?.id;
    final isPatient =
        prescription.patientId == SupabaseService().currentUser?.id;
    // PRE-6 (audit Module 25, Étape 2/3, 30/08/2026) : `isPharmacy` était
    // figé en dur à `false` (« Would check pharmacy staff ») — les actions
    // réservées à la pharmacie (Valider/Refuser/Dispenser) étaient donc
    // définitivement inatteignables, quel que soit le compte connecté.
    // Corrigé par un vrai contrôle, calqué sur la logique de
    // `is_pharmacy_staff()` côté SQL (role pharmacien + rattachement exact
    // à la pharmacie destinataire), déjà exposée côté client par
    // `AuthProvider.userRole`/`pharmacyId` depuis l'audit du Module 1 (AUT).
    final authProvider = context.watch<AuthProvider>();
    final isPharmacy =
        authProvider.effectiveRole == UserRole.pharmacien &&
        authProvider.pharmacyId != null &&
        authProvider.pharmacyId == prescription.pharmacyId;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    'e-Prescription #${prescription.prescriptionNumber}',
                    style: context.text.heading2,
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
                    // Status card
                    GlassCard(
                      glow: true,
                      glowColor: _statusColor(prescription.status),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _statusColor(prescription.status),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${prescription.statusIcon} ${prescription.statusLabel}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor(prescription.status),
                                  ),
                                ),
                                Text(
                                  'Prescrit le ${_formatDate(prescription.prescribedAt)}',
                                  style: context.text.body2,
                                ),
                                Text(
                                  'Valable jusqu\'au ${_formatDate(prescription.validUntil)}',
                                  style: context.text.micro,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Patient',
                            prescription.patientName ?? prescription.patientId,
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow(
                            'Médecin',
                            prescription.doctorName ?? prescription.doctorId,
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          if (prescription.pharmacyName != null) ...[
                            _buildInfoRow(
                              'Pharmacie',
                              prescription.pharmacyName!,
                            ),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (prescription.diagnosis != null) ...[
                            _buildInfoRow(
                              'Diagnostic',
                              prescription.diagnosis!,
                            ),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (prescription.notes != null) ...[
                            _buildInfoRow('Notes', prescription.notes!),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (prescription.isRenewable) ...[
                            _buildInfoRow(
                              'Renouvelable',
                              'Oui (${prescription.renewableUsed}/${prescription.renewableCount})',
                            ),
                          ],
                          if (prescription.accessCode != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Code d\'accès',
                              prescription.accessCode!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items
                    if (provider.items.isNotEmpty) ...[
                      Text('Médicaments', style: context.text.heading3),
                      const SizedBox(height: 8),
                      ...provider.items.map((item) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: context.palette.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.palette.borderSubtle,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.medicationName,
                                style: context.text.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${item.dosage} • ${item.frequency} • ${item.duration}',
                                style: context.text.body2,
                              ),
                              Text(
                                'Quantité: ${item.quantity}',
                                style: context.text.micro,
                              ),
                              if (item.instructions != null)
                                Text(
                                  item.instructions!,
                                  style: context.text.micro.copyWith(
                                    color: context.palette.textSecondary,
                                  ),
                                ),
                              if (item.isSubstitutionAllowed)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: context.palette.secondary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Substitution autorisée',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: context.palette.secondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // History
                    if (provider.history.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Historique', style: context.text.heading3),
                      const SizedBox(height: 8),
                      ...provider.history.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timeline,
                                size: 14,
                                color: context.palette.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${entry.oldStatus ?? 'Création'} → ${entry.newStatus}',
                                  style: context.text.micro,
                                ),
                              ),
                              Text(
                                _formatDate(entry.createdAt),
                                style: context.text.micro,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),

                    // Actions
                    if (isDoctor && prescription.status == 'draft') ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Envoyer',
                              icon: Icons.send,
                              onPressed: () async {
                                final success = await provider.updateStatus(
                                  prescription.id,
                                  'sent',
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Prescription envoyée'),
                                      backgroundColor: context.palette.success,
                                    ),
                                  );
                                  provider.loadPrescription(prescription.id);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Annuler',
                              icon: Icons.close,
                              onPressed: () async {
                                final success = await provider.updateStatus(
                                  prescription.id,
                                  'cancelled',
                                  notes: 'Annulé par le médecin',
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Prescription annulée'),
                                    ),
                                  );
                                  provider.loadPrescription(prescription.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (isPharmacy && prescription.status == 'sent') ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Valider',
                              icon: Icons.check_circle,
                              onPressed: () async {
                                final success = await provider.updateStatus(
                                  prescription.id,
                                  'validated',
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Prescription validée'),
                                      backgroundColor: context.palette.success,
                                    ),
                                  );
                                  provider.loadPrescription(prescription.id);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Refuser',
                              icon: Icons.close,
                              onPressed: () async {
                                final success = await provider.updateStatus(
                                  prescription.id,
                                  'cancelled',
                                  notes: 'Refusé par la pharmacie',
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Prescription refusée'),
                                    ),
                                  );
                                  provider.loadPrescription(prescription.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (isPharmacy && prescription.status == 'validated') ...[
                      PrimaryButton(
                        label: 'Dispenser',
                        icon: Icons.medication,
                        onPressed: () async {
                          final success = await provider.updateStatus(
                            prescription.id,
                            'dispensed',
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Médicaments dispensés'),
                                backgroundColor: context.palette.success,
                              ),
                            );
                            provider.loadPrescription(prescription.id);
                          }
                        },
                      ),
                    ],

                    if (isPatient && prescription.isActive) ...[
                      SecondaryButton(
                        label: 'Annuler ma prescription',
                        icon: Icons.close,
                        onPressed: () async {
                          final success = await provider.updateStatus(
                            prescription.id,
                            'cancelled',
                            notes: 'Annulé par le patient',
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Prescription annulée'),
                              ),
                            );
                            provider.loadPrescription(prescription.id);
                          }
                        },
                      ),
                    ],

                    if (!prescription.isActive) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.palette.textSecondary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              prescription.status == 'dispensed'
                                  ? Icons.done_all
                                  : Icons.block,
                              color: context.palette.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cette prescription est ${prescription.statusLabel.toLowerCase()}',
                                style: context.text.body2,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: context.text.label)),
          Expanded(child: Text(value, style: context.text.body1)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return context.palette.textSecondary;
      case 'sent':
        return context.palette.primary;
      case 'received':
        return context.palette.warning;
      case 'validated':
        return context.palette.success;
      case 'dispensed':
        return context.palette.secondary;
      case 'expired':
        return context.palette.danger;
      case 'cancelled':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
    }
  }
}
