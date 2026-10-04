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
import '../providers/teleconsult_provider.dart';
import '../models/consultation.dart';
import '../models/consultation_status.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class TeleconsultBookingScreen extends StatefulWidget {
  const TeleconsultBookingScreen({super.key});

  @override
  State<TeleconsultBookingScreen> createState() =>
      _TeleconsultBookingScreenState();
}

class _TeleconsultBookingScreenState extends State<TeleconsultBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProfessionalId;
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Audit Module 15 (CNS, 29/08/2026) : charge les professionnels réels
    // (professional_profiles.is_verified/is_accepting_new_patients) au lieu
    // de la liste mockée retirée ci-dessus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeleconsultProvider>().loadProfessionals();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Extrait le nom affichable d'une entrée `professional_profiles`
  /// embarquant `profiles(full_name)` (voir
  /// `TeleconsultService.getAvailableProfessionals()` — `phone` retiré de
  /// cette requête, audit Module 15, 2ème refus de clôture, point de
  /// contrôle données personnelles).
  String _professionalName(Map<String, dynamic> pro) {
    final profile = pro['profiles'] as Map<String, dynamic>?;
    return (profile?['full_name'] as String?)?.trim().isNotEmpty == true
        ? profile!['full_name'] as String
        : 'Professionnel de santé';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeleconsultProvider>();

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
                        'Prendre un rendez-vous',
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
                      // Professional selection
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  'Aucun professionnel disponible pour le moment',
                                  style: context.text.body2,
                                ),
                              )
                            else
                              ...provider.professionals.map((pro) {
                                final id = pro['id'] as String;
                                final name = _professionalName(pro);
                                final specialty =
                                    (pro['specialty'] as String?) ??
                                    'Non spécifié';
                                final isSelected =
                                    _selectedProfessionalId == id;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedProfessionalId = id;
                                      _selectedDate = null;
                                      _selectedTime = null;
                                    });
                                    // Load slots for this professional
                                    provider.loadAvailabilitySlots(id);
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
                                              .accentPurple
                                              .withValues(alpha: 0.2),
                                          child: Text(
                                            name.isNotEmpty ? name[0] : '?',
                                            style: const TextStyle(
                                              color: PharmaConnectColors
                                                  .accentPurple,
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
                                                name,
                                                style: PharmaConnectTypography
                                                    .body1,
                                              ),
                                              Text(
                                                specialty,
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

                      // Date and time selection
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
                              // Date picker
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
                                    // Load available time slots for this date
                                    provider.loadAvailableSlotsForDate(
                                      _selectedProfessionalId!,
                                      date,
                                    );
                                  }
                                },
                              ),
                              // Time slots
                              if (_selectedDate != null) ...[
                                Divider(color: context.palette.veil(0.12)),
                                const SizedBox(height: 8),
                                if (provider.isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (provider.availableSlotsForDate.isEmpty)
                                  Text(
                                    'Aucun créneau disponible pour cette date',
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
                                        onTap: () {
                                          setState(() => _selectedTime = slot);
                                        },
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
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Reason and notes
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motif de la consultation',
                              style: context.text.heading3,
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Motif',
                              hint:
                                  'Décrivez brièvement le motif de la consultation',
                              controller: _reasonController,
                              prefixIcon: Icons.description,
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 12),
                            GlassInput(
                              label: 'Notes supplémentaires (optionnel)',
                              hint:
                                  'Informations complémentaires pour le professionnel',
                              controller: _notesController,
                              prefixIcon: Icons.note_add,
                              keyboardType: TextInputType.multiline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit
                      PrimaryButton(
                        label: _isLoading
                            ? 'Enregistrement...'
                            : 'Prendre rendez-vous',
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

    if (_selectedProfessionalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un professionnel')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un créneau horaire'),
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

    final consultation = Consultation(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      professionalId: _selectedProfessionalId!,
      scheduledAt: _selectedTime!,
      durationMinutes: 30,
      status: ConsultationStatus.pending,
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context
        .read<TeleconsultProvider>()
        .createConsultation(consultation);
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Votre rendez-vous a été envoyé pour confirmation'),
          backgroundColor: context.palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<TeleconsultProvider>().error ??
                'Erreur lors de la prise de rendez-vous',
          ),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }
}
