import 'dart:io';
import 'package:pharma_connect/core/utils/user_message.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/utils/pharmacy_position.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/auth_provider.dart';
import '../services/pharmacy_service.dart';
import '../../search/services/location_service.dart';
import '../widgets/phone_input_field.dart';
import '../../pharmacy_staff/widgets/pending_invitations_card.dart';
import '../../../core/theme/palette.dart';

/// RG-AUT-01 (audit Module 1, 29/08/2026) : soumet réellement la candidature
/// d'officine à public.pharmacies via PharmacyService, à l'état 'pending'.
/// Avant ce correctif, cet écran ne persistait rien nulle part (délai
/// simulé) — voir le rapport de clôture Module 1 pour le détail. Le compte
/// reste utilisable après soumission (accès au tableau de bord), mais
/// fonctionnellement inerte pour tout ce qui exige is_pharmacy_staff() —
/// c'est-à-dire toute écriture de stock/vente/etc. — tant que le back-office
/// GSG n'a pas fait passer le statut à 'verified'/'active' (voir la
/// migration 20260829013000).
class LicenseVerificationScreen extends StatefulWidget {
  const LicenseVerificationScreen({super.key});

  @override
  State<LicenseVerificationScreen> createState() =>
      _LicenseVerificationScreenState();
}

class _LicenseVerificationScreenState extends State<LicenseVerificationScreen> {
  final _pharmacyNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pharmacyService = PharmacyService();
  String? _phoneE164;
  File? _licenseImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  String? _locationMessage;

  @override
  void dispose() {
    _pharmacyNameController.dispose();
    _licenseNumberController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// C252 : lit la position de l'appareil à la demande. Sans position
  /// (localisation coupée, permission refusée, délai dépassé), rien n'est
  /// enregistré et la candidature reste possible.
  Future<void> _useCurrentPosition() async {
    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });
    final position = await LocationService().getCurrentPositionOrNull();
    if (!mounted) return;
    // Même contrôle que la saisie par l'administrateur : une position
    // impossible n'est pas gardée ; hors de la Guinée, elle est gardée avec
    // un avertissement.
    final valid =
        position != null &&
        PharmacyPosition.validate(position.latitude, position.longitude) ==
            null;
    setState(() {
      _isLocating = false;
      _latitude = valid ? position.latitude : null;
      _longitude = valid ? position.longitude : null;
      if (position == null) {
        _locationMessage =
            'Position indisponible (localisation coupée ou refusée). Vous '
            'pouvez soumettre sans position : GSG pourra la saisir.';
      } else if (!valid) {
        _locationMessage =
            'Position lue invalide : elle n\'est pas enregistrée. Vous '
            'pouvez soumettre sans position : GSG pourra la saisir.';
      } else if (PharmacyPosition.isOutsideGuinea(
        position.latitude,
        position.longitude,
      )) {
        _locationMessage =
            '${PharmacyPosition.outsideGuineaWarning} Vous pouvez la retirer '
            'ou soumettre telle quelle.';
      } else {
        _locationMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SizedBox(
            width: 480,
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '◈',
                        style: TextStyle(
                          fontSize: 28,
                          color: context.palette.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PHARMACONNECT',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.palette.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      KernelBadge(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Vérification de licence', style: context.text.heading2),
                  const SizedBox(height: 8),
                  Text(
                    'Pour activer votre compte pharmacie, veuillez fournir les informations suivantes.',
                    style: context.text.body2,
                  ),
                  const SizedBox(height: 24),
                  // C209 : un employé d'une officine déjà inscrite accepte
                  // ici l'invitation de son titulaire.
                  const PendingInvitationsCard(),

                  GlassInput(
                    label: 'Nom de l\'officine',
                    hint: 'Ex: Pharmacie Centrale',
                    controller: _pharmacyNameController,
                    prefixIcon: Icons.local_pharmacy,
                  ),
                  const SizedBox(height: 16),
                  GlassInput(
                    label: 'Numéro de licence',
                    hint: 'Ex: DNPM-2024-001',
                    controller: _licenseNumberController,
                    prefixIcon: Icons.badge,
                  ),
                  const SizedBox(height: 16),
                  GlassInput(
                    label: 'Nom du titulaire',
                    hint: 'Ex: Dr. Jean Dupont',
                    controller: _nameController,
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  PhoneInputField(
                    onChanged: (e164) => setState(() => _phoneE164 = e164),
                  ),
                  const SizedBox(height: 16),
                  GlassInput(
                    label: 'Adresse de l\'officine',
                    hint: 'Ex: Quartier Almamya, Kaloum, Conakry',
                    controller: _addressController,
                    prefixIcon: Icons.location_on,
                  ),
                  const SizedBox(height: 16),
                  // C252 : position facultative. La permission de
                  // localisation n'est demandée qu'à l'appui sur ce bouton ;
                  // refusée, la candidature part sans position.
                  Text(
                    'Position de l\'officine (optionnel)',
                    style: context.text.label,
                  ),
                  const SizedBox(height: 8),
                  if (_latitude != null && _longitude != null)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: context.palette.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Position enregistrée : '
                            '${_latitude!.toStringAsFixed(5)}, '
                            '${_longitude!.toStringAsFixed(5)}',
                            style: context.text.body2,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _latitude = null;
                            _longitude = null;
                            _locationMessage = null;
                          }),
                          child: const Text('Retirer'),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _isLocating ? null : _useCurrentPosition,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: const Text(
                        'Utiliser ma position actuelle\n'
                        '(je suis dans mon officine)',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_locationMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(_locationMessage!, style: context.text.micro),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Photo de la licence (optionnel)',
                    style: context.text.label,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickLicenseImage(),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: context.palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.palette.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: _licenseImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_licenseImage!),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: context.palette.textSecondary,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Toucher pour ajouter une photo',
                                    style: TextStyle(
                                      color: context.palette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.palette.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.palette.warning.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: context.palette.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'La vérification peut prendre jusqu\'à 48h. Vous serez notifié par email.',
                            style: context.text.micro,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Soumettre la vérification',
                    isLoading: _isSubmitting || auth.isLoading,
                    onPressed: () async {
                      if (_pharmacyNameController.text.trim().isEmpty ||
                          _nameController.text.trim().isEmpty ||
                          _addressController.text.trim().isEmpty ||
                          _phoneE164 == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Veuillez remplir tous les champs obligatoires',
                            ),
                            backgroundColor: context.palette.danger,
                          ),
                        );
                        return;
                      }

                      setState(() => _isSubmitting = true);

                      // RG-AUT-01 (audit Module 1, 29/08/2026) : soumission
                      // réelle plutôt que simulée — voir PharmacyService et
                      // la migration 20260829013000. La photo de licence
                      // n'est pas encore téléversée (pas de bucket Storage
                      // dédié configuré pour ce module) : chantier séparé,
                      // documenté plutôt que simulé silencieusement.
                      String? errorMessage;
                      try {
                        await _pharmacyService.submitLicenseVerification(
                          pharmacyName: _pharmacyNameController.text.trim(),
                          managerName: _nameController.text.trim(),
                          phone: _phoneE164!,
                          address: _addressController.text.trim(),
                          licenseNumber: _licenseNumberController.text.trim(),
                          latitude: _latitude,
                          longitude: _longitude,
                        );
                      } catch (e) {
                        errorMessage = userMessage(e);
                      }

                      if (!context.mounted) return;
                      setState(() => _isSubmitting = false);

                      if (errorMessage == null) {
                        // C213 : l'état du compte passe à « candidature en
                        // cours de vérification » (bandeau du tableau de bord).
                        await auth.refreshAccountStatus();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Candidature soumise. Votre compte est actif ; '
                              'les fonctions officine (stock, ventes...) '
                              'seront disponibles après vérification par '
                              'l\'équipe GSG.',
                            ),
                            backgroundColor: context.palette.success,
                          ),
                        );
                        context.go('/dashboard');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Échec de la soumission : $errorMessage',
                            ),
                            backgroundColor: context.palette.danger,
                          ),
                        );
                      }
                    },
                  ),
                  // C213 / D64 : sans officine, le compte reste utilisable
                  // comme un compte patient ; le tableau de bord rappelle
                  // l'inscription et les invitations.
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Plus tard : continuer sans officine'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickLicenseImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() => _licenseImage = File(image.path));
      }
    } catch (e) {
      // ignore
    }
  }
}
