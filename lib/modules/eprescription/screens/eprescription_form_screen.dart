import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/eprescription_provider.dart';
import '../models/eprescription.dart';
import '../models/eprescription_item.dart';
import 'package:pharma_connect/core/theme/palette.dart';

// PRE-5 (audit Module 25, Étape 2/3, 30/08/2026) : écran de création
// d'ordonnance électronique, jusqu'ici totalement absent du module (voir
// le rapport d'audit, §4, constat d'ouverture PRE-5 — le bouton « Nouvelle
// prescription » naviguait vers un écran de détail en lecture seule qui
// tentait de charger une prescription d'id littéral 'new', un UUID
// invalide). Nouvel écran dédié, routé sur '/eprescription/new' (voir
// app_router.dart), réservé au rôle professionnel (RG-PRE-01, désormais
// également appliquée côté RLS — voir la migration corrective du module).
//
// Limite assumée, identique à celle documentée pour ASR-3/D42 (Module 24) :
// aucun sélecteur de patient n'existe nulle part dans le codebase — saisie
// par identifiant UUID en attendant un chantier de conception dédié.
class EPrescriptionFormScreen extends StatefulWidget {
  const EPrescriptionFormScreen({super.key});

  @override
  State<EPrescriptionFormScreen> createState() =>
      _EPrescriptionFormScreenState();
}

class _ItemDraft {
  final medicationNameController = TextEditingController();
  final dosageController = TextEditingController();
  final frequencyController = TextEditingController();
  final durationController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final instructionsController = TextEditingController();
  bool isSubstitutionAllowed = false;

  void dispose() {
    medicationNameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    durationController.dispose();
    quantityController.dispose();
    instructionsController.dispose();
  }
}

class _EPrescriptionFormScreenState extends State<EPrescriptionFormScreen> {
  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final _formKey = GlobalKey<FormState>();
  final _patientIdController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _renewableCountController = TextEditingController(text: '0');

  DateTime _validUntil = DateTime.now().add(const Duration(days: 90));
  bool _isRenewable = false;
  int _renewableCount = 0;
  bool _isSaving = false;
  String? _error;

  final List<_ItemDraft> _items = [_ItemDraft()];

  @override
  void dispose() {
    _patientIdController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    _renewableCountController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EPrescriptionProvider>();

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
                      'Nouvelle prescription électronique',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
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
                            Text('Patient', style: context.text.heading3),
                            const SizedBox(height: 4),
                            Text(
                              'Aucun sélecteur de patient n\'existe encore '
                              'dans ce module — voir le registre (même '
                              'limite que l\'adhésion d\'assurance).',
                              style: context.text.micro,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _patientIdController,
                              label: 'ID Patient (UUID)',
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
                            Text(
                              'Détails de la prescription',
                              style: context.text.heading3,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _diagnosisController,
                              label: 'Diagnostic (optionnel)',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _notesController,
                              label: 'Notes (optionnel)',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            _buildDateField(
                              label: 'Valable jusqu\'au',
                              value: _validUntil,
                              onPick: (d) => setState(() => _validUntil = d),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Renouvelable',
                                style: context.text.body2,
                              ),
                              value: _isRenewable,
                              onChanged: (v) => setState(() {
                                _isRenewable = v;
                                if (!v) _renewableCount = 0;
                              }),
                            ),
                            if (_isRenewable)
                              _buildTextField(
                                controller: _renewableCountController,
                                label: 'Nombre de renouvellements',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => _renewableCount =
                                    int.tryParse(v.trim()) ?? 0,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Médicaments',
                                    style: context.text.heading3,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: context.palette.primary,
                                  ),
                                  onPressed: () =>
                                      setState(() => _items.add(_ItemDraft())),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Au moins un médicament est requis.',
                              style: context.text.micro,
                            ),
                            const SizedBox(height: 8),
                            for (var i = 0; i < _items.length; i++)
                              _buildItemForm(i),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: context.text.body2.copyWith(
                            color: context.palette.danger,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (provider.error != null) ...[
                        Text(
                          provider.error!,
                          style: context.text.body2.copyWith(
                            color: context.palette.danger,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      PrimaryButton(
                        label: 'Créer la prescription',
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

  Widget _buildItemForm(int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Médicament ${index + 1}',
                  style: context.text.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_items.length > 1)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: context.palette.danger,
                  ),
                  onPressed: () => setState(() {
                    _items[index].dispose();
                    _items.removeAt(index);
                  }),
                ),
            ],
          ),
          _buildTextField(
            controller: item.medicationNameController,
            label: 'Nom du médicament',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: item.dosageController,
                  label: 'Dosage',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: item.quantityController,
                  label: 'Quantité',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return (n == null || n <= 0) ? 'Invalide' : null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: item.frequencyController,
                  label: 'Fréquence',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: item.durationController,
                  label: 'Durée',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: item.instructionsController,
            label: 'Instructions (optionnel)',
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('Substitution autorisée', style: context.text.body2),
            value: item.isSubstitutionAllowed,
            onChanged: (v) =>
                setState(() => item.isSubstitutionAllowed = v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onPick,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text('${value.day}/${value.month}/${value.year}'),
      ),
    );
  }

  String? _validateUuid(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ requis';
    if (!_uuidPattern.hasMatch(v.trim())) return 'UUID invalide';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      setState(() => _error = 'Au moins un médicament est requis.');
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now().toUtc();
    final doctorId = SupabaseService().currentUser!.id;
    final prescription = EPrescription(
      id: '',
      prescriptionNumber: '',
      patientId: _patientIdController.text.trim(),
      doctorId: doctorId,
      prescribedAt: now,
      validUntil: _validUntil,
      status: 'draft',
      diagnosis: _diagnosisController.text.trim().isEmpty
          ? null
          : _diagnosisController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isRenewable: _isRenewable,
      renewableCount: _isRenewable ? _renewableCount : 0,
      createdAt: now,
      updatedAt: now,
    );

    final provider = context.read<EPrescriptionProvider>();
    final success = await provider.savePrescription(prescription);

    if (!mounted) return;

    if (!success) {
      setState(() => _isSaving = false);
      return;
    }

    final saved = provider.selectedPrescription;
    if (saved == null) {
      setState(() => _isSaving = false);
      return;
    }

    for (final item in _items) {
      await provider.addItem(
        EPrescriptionItem(
          id: '',
          eprescriptionId: saved.id,
          medicationName: item.medicationNameController.text.trim(),
          dosage: item.dosageController.text.trim(),
          frequency: item.frequencyController.text.trim(),
          duration: item.durationController.text.trim(),
          quantity: int.tryParse(item.quantityController.text.trim()) ?? 1,
          instructions: item.instructionsController.text.trim().isEmpty
              ? null
              : item.instructionsController.text.trim(),
          isSubstitutionAllowed: item.isSubstitutionAllowed,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    // Patron identique à enrollment_form_screen.dart (ASR-3) : context.go()
    // plutôt que context.pop(), pour remplacer l'écran de création par
    // l'écran de détail de la prescription nouvellement créée.
    context.go('/eprescription/${saved.id}');
  }
}
