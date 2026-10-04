import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../providers/homecare_provider.dart';
import '../models/intervention.dart';
import '../models/homecare_status.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class HomecareBookingScreen extends StatefulWidget {
  const HomecareBookingScreen({super.key});

  @override
  State<HomecareBookingScreen> createState() => _HomecareBookingScreenState();
}

class _HomecareBookingScreenState extends State<HomecareBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProfessionalId;
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  final _reasonController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Audit Module 18 (HOM, 30/08/2026) : charge les professionnels réels
    // (professional_profiles.is_verified/is_accepting_new_patients/
    // home_visit_fee non nul) au lieu de `_mockProfessionals` (IDs non-UUID,
    // même défaut que C62 du Module 15), retiré ci-dessus — voir
    // `HomecareService.getAvailableProfessionals()`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomecareProvider>().loadProfessionals();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _professionalName(Map<String, dynamic> pro) {
    final profile = pro['profiles'] as Map<String, dynamic>?;
    return (profile?['full_name'] as String?)?.trim().isNotEmpty == true
        ? profile!['full_name'] as String
        : 'Professionnel';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomecareProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                        'Demander une intervention',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choisissez un professionnel',
                              style: context.text.heading3,
                            ),
                            const SizedBox(height: 8),
                            if (provider.isLoading &&
                                provider.professionals.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (provider.professionals.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Aucun professionnel disponible pour une visite à domicile actuellement',
                                  style: context.text.body2,
                                ),
                              )
                            else
                              ...provider.professionals.map((pro) {
                                final proId = pro['id'] as String;
                                final proName = _professionalName(pro);
                                final proSpecialty =
                                    (pro['specialty'] as String?) ??
                                    'Non spécifié';
                                final isSelected =
                                    _selectedProfessionalId == proId;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedProfessionalId = proId;
                                      _selectedDate = null;
                                      _selectedTime = null;
                                    });
                                    provider.loadAvailabilitySlots(proId);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? context.palette.primary.withValues(
                                              alpha: 0.1,
                                            )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? context.palette.primary
                                            : context.palette.surface,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: PharmaConnectColors
                                              .accentGreen
                                              .withValues(alpha: 0.2),
                                          child: Text(
                                            proName.isNotEmpty
                                                ? proName[0]
                                                : '?',
                                            style: const TextStyle(
                                              color: PharmaConnectColors
                                                  .accentGreen,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                proName,
                                                style: PharmaConnectTypography
                                                    .body1,
                                              ),
                                              Text(
                                                proSpecialty,
                                                style: PharmaConnectTypography
                                                    .body2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: context.palette.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_selectedProfessionalId != null) ...[
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choisissez la date et l\'heure',
                                style: context.text.heading3,
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                title: const Text('Date'),
                                subtitle: Text(
                                  _selectedDate != null
                                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                      : 'Sélectionnez une date',
                                ),
                                leading: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(
                                      const Duration(days: 1),
                                    ),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 30),
                                    ),
                                    builder: (context, child) {
                                      return Theme(
                                        data: ThemeData.dark().copyWith(
                                          colorScheme: ColorScheme.dark(
                                            primary: context.palette.primary,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _selectedDate = date;
                                      _selectedTime = null;
                                    });
                                    provider.loadAvailableSlotsForDate(
                                      _selectedProfessionalId!,
                                      date,
                                    );
                                  }
                                },
                              ),
                              if (_selectedDate != null) ...[
                                Divider(color: context.palette.veil(0.12)),
                                const SizedBox(height: 8),
                                if (provider.isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (provider.availableSlotsForDate.isEmpty)
                                  Text(
                                    'Aucun créneau disponible',
                                    style: context.text.body2,
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: provider.availableSlotsForDate.map((
                                      slot,
                                    ) {
                                      final isSelected = _selectedTime == slot;
                                      return GestureDetector(
                                        onTap: () => setState(
                                          () => _selectedTime = slot,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? context.palette.primary
                                                      .withValues(alpha: 0.2)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? PharmaConnectColors
                                                        .accentCyan
                                                  : context.palette.veil(0.24),
                                            ),
                                          ),
                                          child: Text(
                                            '${slot.hour}:${slot.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? PharmaConnectColors
                                                        .accentCyan
                                                  : PharmaConnectColors
                                                        .textPrimary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Détails de l\'intervention',
                              style: context.text.heading3,
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Motif',
                              hint: 'Raison de l\'intervention',
                              controller: _reasonController,
                              prefixIcon: Icons.description,
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Adresse',
                              hint: 'Lieu de l\'intervention',
                              controller: _addressController,
                              prefixIcon: Icons.location_on,
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Notes (optionnel)',
                              hint: 'Informations complémentaires',
                              controller: _notesController,
                              prefixIcon: Icons.note_add,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: _isLoading
                            ? 'Enregistrement...'
                            : 'Demander l\'intervention',
                        isLoading: _isLoading,
                        onPressed: _submitBooking,
                      ),
                      const SizedBox(height: 8),
                      TertiaryButton(
                        label: 'Annuler',
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProfessionalId == null ||
        _selectedTime == null ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
        ),
      );
      return;
    }

    final patientId = SupabaseService().currentUser?.id;
    if (patientId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    setState(() => _isLoading = true);

    final intervention = Intervention(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      professionalId: _selectedProfessionalId!,
      scheduledAt: _selectedTime!,
      durationMinutes: 60,
      status: HomecareStatus.pending,
      reason: _reasonController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context.read<HomecareProvider>().createIntervention(
      intervention,
    );
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Votre demande d\'intervention a été envoyée'),
          backgroundColor: context.palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<HomecareProvider>().error ?? 'Erreur'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }
}
