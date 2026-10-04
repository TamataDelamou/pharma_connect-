import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import '../providers/triage_provider.dart';
import '../models/triage_status.dart';
import '../models/triage_patient.dart';
import '../models/triage_assessment.dart';
import '../../healthrecord/widgets/emergency_access_dialog.dart';
import 'package:pharma_connect/core/theme/palette.dart';

// Audit Module 17 (TRI, 30/08/2026), correctifs de compilation (bugs 2-4) :
// ce fichier utilisait `SupabaseService()` (lignes ~56, ~605),
// `TriagePatient` comme type explicite de paramètre (`_showAssignDialog`) et
// `TriageAssessment(...)` comme constructeur (`_showAssessmentDialog`) sans
// importer aucun des trois — trois `Undefined name`/`Undefined class`
// distincts, même motif que C59 (Module 15). Imports ajoutés ci-dessus.

class TriageDetailScreen extends StatefulWidget {
  final String patientId;

  const TriageDetailScreen({super.key, required this.patientId});

  @override
  State<TriageDetailScreen> createState() => _TriageDetailScreenState();
}

class _TriageDetailScreenState extends State<TriageDetailScreen> {
  final _notesController = TextEditingController();
  String? _assignedDepartment;
  String? _assignedDoctorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TriageProvider>().loadPatient(widget.patientId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final patient = context.watch<TriageProvider>().selectedPatient;
    if (patient != null) {
      _notesController.text = patient.notes ?? '';
      _assignedDepartment = patient.assignedDepartment;
      _assignedDoctorId = patient.assignedDoctorId;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final patient = provider.selectedPatient;
    final isNurse = SupabaseService().currentUser?.id == patient?.triageNurseId;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (patient == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Patient introuvable',
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
                      'Dossier de triage',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                // C219 / D63 : bris de glace. Un professionnel affilié à
                // l'hôpital ouvre le dossier de santé du patient pendant la
                // prise en charge (motif obligatoire, 24 heures, tracé et
                // visible par le patient). Le serveur vérifie l'affiliation.
                if (!patient.status.isCompleted &&
                    SupabaseService().currentUser?.id != patient.patientId) ...[
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _openEmergencyAccess(context, patient),
                    icon: const Icon(Icons.emergency),
                    label: const Text('Dossier de santé (urgence)'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.palette.danger),
                      foregroundColor: context.palette.danger,
                    ),
                  ),
                ],
                if (patient.status.isActive && isNurse) ...[
                  const SizedBox(width: 16),
                  // Audit Module 17 (TRI, 30/08/2026) : TriageAIScreen
                  // existait déjà (règles réelles, pas factices) mais
                  // n'était accessible depuis aucun écran — bouton ajouté
                  // ici, même visibilité que « Évaluer ».
                  OutlinedButton.icon(
                    onPressed: () => context.push('/triage/${patient.id}/ai'),
                    icon: const Icon(Icons.psychology),
                    label: const Text('Analyse IA'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.palette.primary),
                      foregroundColor: context.palette.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAssessmentDialog(context),
                    icon: const Icon(Icons.assessment),
                    label: const Text('Évaluer'),
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
                    GlassCard(
                      glow: true,
                      glowColor: _priorityColor(patient.priorityLevel),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _priorityColor(patient.priorityLevel),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Priorité ${patient.priorityLevel}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _priorityColor(
                                      patient.priorityLevel,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Statut : ${patient.status.label}',
                                  style: context.text.body2,
                                ),
                                Text(
                                  'Arrivé : ${_formatDate(patient.arrivalTime)}',
                                  style: context.text.micro,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _priorityColor(
                                patient.priorityLevel,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _priorityLabel(patient.priorityLevel),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _priorityColor(patient.priorityLevel),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Patient',
                            patient.patientName ?? patient.patientId,
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow('Motif', patient.chiefComplaint),
                          if (patient.symptoms != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow('Symptômes', patient.symptoms!),
                          ],
                          if (patient.vitalSigns.isNotEmpty) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildVitalSigns(patient.vitalSigns),
                          ],
                          if (patient.assignedDepartment != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Service',
                              patient.assignedDepartment!,
                            ),
                          ],
                          if (patient.assignedDoctorId != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Médecin',
                              patient.doctorName ?? patient.assignedDoctorId!,
                            ),
                          ],
                          if (patient.notes != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow('Notes', patient.notes!),
                          ],
                          if (patient.triageResult != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow('Résultat', patient.triageResult!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Assessments
                    if (provider.assessments.isNotEmpty) ...[
                      Text('Évaluations', style: context.text.heading3),
                      const SizedBox(height: 8),
                      ...provider.assessments.map((assessment) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
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
                                'Évaluation du ${_formatDate(assessment.assessmentTime)}',
                                style: context.text.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (assessment.triageCategory != null)
                                Text(
                                  'Catégorie : ${assessment.triageCategory}',
                                ),
                              if (assessment.painScore != null)
                                Text('Douleur : ${assessment.painScore}/10'),
                              if (assessment.recommendations != null)
                                Text(
                                  'Recommandations : ${assessment.recommendations}',
                                ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Actions
                    if (patient.status == TriageStatus.waiting && isNurse) ...[
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Démarrer l\'évaluation',
                        icon: Icons.play_arrow,
                        onPressed: () async {
                          final success = await provider.updatePatientStatus(
                            patient.id,
                            TriageStatus.inAssessment,
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Évaluation commencée'),
                                backgroundColor: context.palette.primary,
                              ),
                            );
                            provider.loadPatient(patient.id);
                          }
                        },
                      ),
                    ],

                    if (patient.status == TriageStatus.inAssessment &&
                        isNurse) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Assigner',
                              icon: Icons.assignment,
                              onPressed: () =>
                                  _showAssignDialog(context, patient),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Transférer',
                              icon: Icons.local_hospital,
                              onPressed: () =>
                                  _showTransferDialog(context, patient),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SecondaryButton(
                        label: 'Sortie',
                        icon: Icons.exit_to_app,
                        onPressed: () async {
                          final success = await provider.updatePatientStatus(
                            patient.id,
                            TriageStatus.discharged,
                            notes: _notesController.text.trim(),
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Patient sorti'),
                                backgroundColor: context.palette.success,
                              ),
                            );
                            provider.loadPatient(patient.id);
                          }
                        },
                      ),
                    ],

                    if (patient.status.isCompleted) ...[
                      const SizedBox(height: 16),
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
                                'Patient ${patient.status == TriageStatus.discharged ? 'sorti' : 'transféré'} le ${_formatDate(patient.dischargedAt ?? DateTime.now())}',
                                style: context.text.body1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Audit Module 17 (TRI, 30/08/2026), correctif de
                    // compilation (bug 5) : `TriageStatus.isPast` n'existe
                    // pas (l'extension ne définit que `isActive`/`isCompleted`,
                    // voir triage_status.dart) — `Undefined getter 'isPast'`.
                    // Remplacé par `isCompleted` (sorti/transféré), seul
                    // état pour lequel un dossier de triage a un sens à être
                    // nettoyé.
                    if (patient.status.isCompleted && isNurse) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, patient.id),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.palette.danger,
                          side: BorderSide(color: context.palette.danger),
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

  Widget _buildVitalSigns(Map<String, dynamic> signs) {
    final children = <Widget>[];
    signs.forEach((key, value) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(_formatVitalName(key), style: context.text.label),
              ),
              Expanded(
                child: Text(value.toString(), style: context.text.body1),
              ),
            ],
          ),
        ),
      );
    });
    return Column(children: children);
  }

  String _formatVitalName(String key) {
    switch (key) {
      case 'hr':
        return 'FC';
      case 'rr':
        return 'FR';
      case 'bp_sys':
        return 'TAS';
      case 'bp_dia':
        return 'TAD';
      case 'temp':
        return 'Température';
      case 'spo2':
        return 'SpO2';
      case 'consciousness':
        return 'Conscience';
      default:
        return key;
    }
  }

  /// C219 / D63 : déclaration de l'urgence puis ouverture du dossier de
  /// santé du patient en lecture.
  Future<void> _openEmergencyAccess(
    BuildContext context,
    TriagePatient patient,
  ) async {
    final granted = await showEmergencyAccessDialog(
      context,
      triagePatientId: patient.id,
    );
    if (!granted || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accès d\'urgence accordé pour 24 heures.')),
    );
    context.push('/healthrecord/patient/${patient.patientId}');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _priorityColor(int level) {
    switch (level) {
      case 1:
        return context.palette.danger;
      case 2:
        return context.palette.warning;
      case 3:
        return context.palette.warningStrong;
      case 4:
        return context.palette.primary;
      case 5:
        return context.palette.success;
      default:
        return context.palette.textSecondary;
    }
  }

  String _priorityLabel(int level) {
    switch (level) {
      case 1:
        return 'Immédiat';
      case 2:
        return 'Urgent';
      case 3:
        return 'Peu urgent';
      case 4:
        return 'Non urgent';
      case 5:
        return 'Routine';
      default:
        return 'Inconnu';
    }
  }

  void _showAssessmentDialog(BuildContext context) {
    final painController = TextEditingController();
    final rrController = TextEditingController();
    final hrController = TextEditingController();
    final bpSysController = TextEditingController();
    final bpDiaController = TextEditingController();
    final tempController = TextEditingController();
    final spo2Controller = TextEditingController();
    String? consciousLevel;
    String? triageCategory;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Évaluation du patient'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                painController,
                'Douleur (0-10)',
                TextInputType.number,
              ),
              _buildTextField(rrController, 'FR (/min)', TextInputType.number),
              _buildTextField(hrController, 'FC (/min)', TextInputType.number),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      bpSysController,
                      'TAS',
                      TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      bpDiaController,
                      'TAD',
                      TextInputType.number,
                    ),
                  ),
                ],
              ),
              _buildTextField(
                tempController,
                'Température (°C)',
                TextInputType.number,
              ),
              _buildTextField(spo2Controller, 'SpO2 (%)', TextInputType.number),
              DropdownButtonFormField<String>(
                value: consciousLevel,
                decoration: const InputDecoration(
                  labelText: 'Niveau de conscience',
                  border: OutlineInputBorder(),
                ),
                items: ['alert', 'verbal', 'pain', 'unresponsive'].map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) => consciousLevel = value,
              ),
              DropdownButtonFormField<String>(
                value: triageCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie de triage',
                  border: OutlineInputBorder(),
                ),
                items:
                    [
                      'resuscitation',
                      'emergency',
                      'urgent',
                      'semi-urgent',
                      'non-urgent',
                    ].map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                onChanged: (value) => triageCategory = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final assessment = TriageAssessment(
                id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                triagePatientId: context
                    .read<TriageProvider>()
                    .selectedPatient!
                    .id,
                nurseId: SupabaseService().currentUser!.id,
                assessmentTime: DateTime.now(),
                painScore: int.tryParse(painController.text),
                respiratoryRate: int.tryParse(rrController.text),
                heartRate: int.tryParse(hrController.text),
                bloodPressureSystolic: int.tryParse(bpSysController.text),
                bloodPressureDiastolic: int.tryParse(bpDiaController.text),
                temperature: double.tryParse(tempController.text),
                oxygenSaturation: int.tryParse(spo2Controller.text),
                consciousnessLevel: consciousLevel,
                triageCategory: triageCategory,
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
              );
              Navigator.pop(ctx);
              final success = await context
                  .read<TriageProvider>()
                  .createAssessment(assessment);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Évaluation enregistrée')),
                );
                context.read<TriageProvider>().loadPatient(widget.patientId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.primary,
              foregroundColor: context.palette.onPrimary,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    TextInputType type,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, TriagePatient patient) {
    // Simple mock departments
    final departments = [
      'Cardiologie',
      'Traumatologie',
      'Pédiatrie',
      'Médecine interne',
      'Chirurgie',
    ];
    final doctors = ['Dr. Diallo', 'Dr. Camara', 'Dr. Sow'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Assigner le patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _assignedDepartment,
              decoration: const InputDecoration(labelText: 'Service'),
              items: departments
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) => setState(() => _assignedDepartment = value),
            ),
            DropdownButtonFormField<String>(
              value: _assignedDoctorId,
              decoration: const InputDecoration(labelText: 'Médecin'),
              items: doctors
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) => setState(() => _assignedDoctorId = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context
                  .read<TriageProvider>()
                  .updatePatientStatus(
                    patient.id,
                    TriageStatus.assigned,
                    assignedDepartment: _assignedDepartment,
                    assignedDoctorId: _assignedDoctorId,
                    notes: _notesController.text.trim(),
                  );
              Navigator.pop(ctx);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patient assigné')),
                );
                // Audit Module 17 (TRI, 30/08/2026), correctif de
                // compilation (bug 6) : référençait `provider`, jamais
                // défini dans cette méthode (ni paramètre, ni variable
                // locale) — `Undefined name 'provider'`. Remplacé par le
                // même accès `context.read<TriageProvider>()` utilisé par
                // le dialogue d'évaluation juste au-dessus.
                context.read<TriageProvider>().loadPatient(patient.id);
              }
            },
            child: const Text('Assigner'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext context, TriagePatient patient) {
    // Similaire à assign
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Supprimer'),
        content: const Text('Supprimer ce dossier de triage ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<TriageProvider>()
                  .deletePatient(id);
              if (success && context.mounted) context.pop();
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
