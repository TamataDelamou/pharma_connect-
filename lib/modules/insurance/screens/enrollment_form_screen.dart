import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/insurance_provider.dart';
import '../models/insurance_enrollment.dart';

// ASR-3 (audit Module 24, Étape 2/3, 30/08/2026) : écran de création
// d'adhésion, jusqu'ici totalement absent du module (voir le rapport
// d'audit, §4, constat d'ouverture ASR-3 — le bouton « Nouveau contrat »
// naviguait vers un écran de détail en lecture seule, qui tentait de charger
// une adhésion d'id littéral 'new', un UUID invalide). Nouvel écran dédié,
// routé sur '/insurance/enroll/new' (voir app_router.dart).
//
// Limite assumée, à documenter au registre : ni la sélection du patient
// (patientId) ni celle du plan (planId) ne disposent d'un sélecteur dédié
// dans ce module — recherche exhaustive confirmée : aucun composant de
// sélection de patient n'existe nulle part ailleurs dans le codebase
// (professionals/hospitals n'ont que des sélecteurs de PROFESSIONNEL/
// ÉTABLISSEMENT, pas de patient), et aucun modèle/service InsurancePlan
// client n'existe pour peupler un sélecteur de plan par compagnie (seule la
// table `insurance_plans` existe côté base). Construire ces deux sélecteurs
// est un chantier de conception à part entière (UI + éventuellement
// nouveau modèle/service), hors du périmètre d'un correctif de routage.
// Saisie par identifiant UUID en attendant — le chemin d'écriture est
// désormais réel et sécurisé (ASR-1/ASR-2, is_gsg_admin()), seule l'ergonomie
// de sélection reste perfectible.
class EnrollmentFormScreen extends StatefulWidget {
  const EnrollmentFormScreen({super.key});

  @override
  State<EnrollmentFormScreen> createState() => _EnrollmentFormScreenState();
}

class _EnrollmentFormScreenState extends State<EnrollmentFormScreen> {
  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final _formKey = GlobalKey<FormState>();
  final _patientIdController = TextEditingController();
  final _planIdController = TextEditingController();
  final _policyNumberController = TextEditingController();
  final _memberNumberController = TextEditingController();
  final _coveragePercentageController = TextEditingController();
  final _annualLimitController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _patientIdController.dispose();
    _planIdController.dispose();
    _policyNumberController.dispose();
    _memberNumberController.dispose();
    _coveragePercentageController.dispose();
    _annualLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsuranceProvider>();

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
                const Expanded(
                  child: Text(
                    'Nouveau contrat d\'assurance',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rattachement',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Identifiants du patient et du plan (aucun '
                              'sélecteur dédié n\'existe encore dans ce '
                              'module — voir le registre).',
                              style: PharmaConnectTypography.micro,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _patientIdController,
                              label: 'ID Patient (UUID)',
                              validator: _validateUuid,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _planIdController,
                              label: 'ID Plan d\'assurance (UUID)',
                              validator: _validateUuid,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Détails du contrat',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _policyNumberController,
                              label: 'N° Police',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Champ requis'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _memberNumberController,
                              label: 'N° Adhérent (optionnel)',
                            ),
                            const SizedBox(height: 12),
                            _buildDateField(
                              label: 'Date de début',
                              value: _startDate,
                              onPick: (d) => setState(() => _startDate = d),
                            ),
                            const SizedBox(height: 12),
                            _buildDateField(
                              label: 'Date d\'expiration (optionnel)',
                              value: _endDate,
                              onPick: (d) => setState(() => _endDate = d),
                              onClear: () => setState(() => _endDate = null),
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _coveragePercentageController,
                              label: 'Taux de couverture % (optionnel)',
                              keyboardType: TextInputType.number,
                              validator: _validatePercentage,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _annualLimitController,
                              label: 'Plafond annuel GNF (optionnel)',
                              keyboardType: TextInputType.number,
                              validator: _validatePositiveInt,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _notesController,
                              label: 'Notes (optionnel)',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (provider.error != null) ...[
                        Text(
                          provider.error!,
                          style: PharmaConnectTypography.body2.copyWith(
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      PrimaryButton(
                        label: 'Créer le contrat',
                        onPressed: _isSaving ? null : _submit,
                        isLoading: _isSaving,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear != null && value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value != null
              ? '${value.day}/${value.month}/${value.year}'
              : 'Non renseignée',
        ),
      ),
    );
  }

  String? _validateUuid(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ requis';
    if (!_uuidPattern.hasMatch(v.trim())) return 'UUID invalide';
    return null;
  }

  String? _validatePercentage(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n < 0 || n > 100) return 'Doit être entre 0 et 100';
    return null;
  }

  String? _validatePositiveInt(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return 'Doit être un nombre positif';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now().toUtc();
    final enrollment = InsuranceEnrollment(
      id: '',
      patientId: _patientIdController.text.trim(),
      planId: _planIdController.text.trim(),
      policyNumber: _policyNumberController.text.trim(),
      memberNumber: _memberNumberController.text.trim().isEmpty
          ? null
          : _memberNumberController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      status: 'active',
      coveragePercentage: _coveragePercentageController.text.trim().isEmpty
          ? null
          : int.tryParse(_coveragePercentageController.text.trim()),
      annualLimit: _annualLimitController.text.trim().isEmpty
          ? null
          : int.tryParse(_annualLimitController.text.trim()),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final success = await context.read<InsuranceProvider>().saveEnrollment(
      enrollment,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      final saved = context.read<InsuranceProvider>().selectedEnrollment;
      if (saved != null) {
        // Patron identique à recall_create_screen.dart après création :
        // context.go() plutôt que context.pop(), pour remplacer l'écran de
        // création par l'écran de détail du contrat nouvellement créé.
        context.go('/insurance/enroll/${saved.id}');
      } else {
        context.pop();
      }
    }
  }
}
