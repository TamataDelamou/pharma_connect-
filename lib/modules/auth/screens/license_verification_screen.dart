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

class LicenseVerificationScreen extends StatefulWidget {
  const LicenseVerificationScreen({super.key});

  @override
  State<LicenseVerificationScreen> createState() =>
      _LicenseVerificationScreenState();
}

class _LicenseVerificationScreenState extends State<LicenseVerificationScreen> {
  final _licenseNumberController = TextEditingController();
  final _nameController = TextEditingController();
  File? _licenseImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _nameController.dispose();
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
                      if (_licenseNumberController.text.trim().isEmpty ||
                          _nameController.text.trim().isEmpty) {
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

                      // Simuler l'envoi de la vérification
                      await Future.delayed(const Duration(seconds: 2));

                      setState(() => _isSubmitting = false);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vérification soumise avec succès !'),
                            backgroundColor: PharmaConnectColors.accentGreen,
                          ),
                        );
                        context.go('/dashboard');
                      }
                    },
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
