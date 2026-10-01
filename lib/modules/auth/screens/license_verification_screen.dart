import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/auth_provider.dart';
import '../services/pharmacy_service.dart';
import '../widgets/phone_input_field.dart';
import '../../pharmacy_staff/widgets/pending_invitations_card.dart';

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

  @override
  void dispose() {
    _pharmacyNameController.dispose();
    _licenseNumberController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
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
                  const Row(
                    children: [
                      Text(
                        '◈',
                        style: TextStyle(
                          fontSize: 28,
                          color: PharmaConnectColors.accentCyan,
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
                            color: PharmaConnectColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      KernelBadge(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Vérification de licence',
                    style: PharmaConnectTypography.heading2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pour activer votre compte pharmacie, veuillez fournir les informations suivantes.',
                    style: PharmaConnectTypography.body2,
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
                  const Text(
                    'Photo de la licence (optionnel)',
                    style: PharmaConnectTypography.label,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickLicenseImage(),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      child: _licenseImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_licenseImage!),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: Colors.white54,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Toucher pour ajouter une photo',
                                    style: TextStyle(
                                      color: Colors.white54,
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
                      color: PharmaConnectColors.accentOrange.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: PharmaConnectColors.accentOrange.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: PharmaConnectColors.accentOrange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'La vérification peut prendre jusqu\'à 48h. Vous serez notifié par email.',
                            style: PharmaConnectTypography.micro,
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
                          const SnackBar(
                            content: Text(
                              'Veuillez remplir tous les champs obligatoires',
                            ),
                            backgroundColor: PharmaConnectColors.accentRed,
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
                        );
                      } catch (e) {
                        errorMessage = e.toString();
                      }

                      if (!context.mounted) return;
                      setState(() => _isSubmitting = false);

                      if (errorMessage == null) {
                        // C213 : l'état du compte passe à « candidature en
                        // cours de vérification » (bandeau du tableau de bord).
                        await auth.refreshAccountStatus();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Candidature soumise. Votre compte est actif ; '
                              'les fonctions officine (stock, ventes...) '
                              'seront disponibles après vérification par '
                              'l\'équipe GSG.',
                            ),
                            backgroundColor: PharmaConnectColors.accentGreen,
                          ),
                        );
                        context.go('/dashboard');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Échec de la soumission : $errorMessage',
                            ),
                            backgroundColor: PharmaConnectColors.accentRed,
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
