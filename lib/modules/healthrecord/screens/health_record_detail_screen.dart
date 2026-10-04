import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/health_record_provider.dart';
import '../widgets/allergy_tile.dart';
import '../widgets/condition_tile.dart';
import '../widgets/medication_tile.dart';
import '../widgets/vaccination_tile.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class HealthRecordDetailScreen extends StatefulWidget {
  final String recordId;

  const HealthRecordDetailScreen({super.key, required this.recordId});

  @override
  State<HealthRecordDetailScreen> createState() =>
      _HealthRecordDetailScreenState();
}

class _HealthRecordDetailScreenState extends State<HealthRecordDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthRecordProvider>().loadRecord(widget.recordId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthRecordProvider>();
    final record = provider.selectedRecord;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (record == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Dossier introuvable',
            style: context.text.body2.copyWith(color: context.palette.danger),
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
            // Header
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
                      'Dossier de santé',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                // C219 : seul le patient modifie son dossier ; un
                // professionnel (lien de soin ou accès d'urgence) le consulte.
                if (record.patientId == SupabaseService().currentUser?.id) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/healthrecord/edit/${record.id}'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.primary,
                      foregroundColor: context.palette.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
                    // General info
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations générales',
                            style: context.text.heading3,
                          ),
                          const SizedBox(height: 12),
                          if (record.bloodType != null) ...[
                            _buildInfoRow('Groupe sanguin', record.bloodType!),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (record.height != null) ...[
                            _buildInfoRow('Taille', '${record.height} cm'),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (record.weight != null) ...[
                            _buildInfoRow('Poids', '${record.weight} kg'),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (record.notes != null) ...[
                            _buildInfoRow('Notes', record.notes!),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Dernière mise à jour : ${_formatDate(record.updatedAt)}',
                            style: context.text.micro.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Allergies
                    if (record.allergies.isNotEmpty) ...[
                      Text('Allergies', style: context.text.heading3),
                      const SizedBox(height: 8),
                      ...record.allergies.map((a) => AllergyTile(allergy: a)),
                      const SizedBox(height: 16),
                    ],

                    // Medical conditions
                    if (record.medicalConditions.isNotEmpty) ...[
                      Text(
                        'Antécédents médicaux',
                        style: context.text.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...record.medicalConditions.map(
                        (c) => ConditionTile(condition: c),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Medications
                    if (record.medications.isNotEmpty) ...[
                      Text(
                        'Traitements en cours',
                        style: context.text.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...record.medications.map(
                        (m) => MedicationTile(medication: m),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Vaccinations
                    if (record.vaccinations.isNotEmpty) ...[
                      Text('Vaccinations', style: context.text.heading3),
                      const SizedBox(height: 8),
                      ...record.vaccinations.map(
                        (v) => VaccinationTile(vaccination: v),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Delete button
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, record.id),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer ce dossier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.palette.danger,
                        side: BorderSide(color: context.palette.danger),
                      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Supprimer le dossier'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce dossier de santé ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<HealthRecordProvider>()
                  .deleteRecord(id);
              if (success && context.mounted) {
                context.pop(); // back to list
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.onDanger,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
