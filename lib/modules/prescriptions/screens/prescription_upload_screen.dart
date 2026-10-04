import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/pilot/pilot_config.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/profile_service.dart';
import '../providers/prescription_provider.dart';
import '../widgets/destination_pharmacy_picker.dart';
import '../widgets/upload_guidance_overlay.dart';
import '../../../core/theme/palette.dart';

class PrescriptionUploadScreen extends StatefulWidget {
  const PrescriptionUploadScreen({super.key});

  @override
  State<PrescriptionUploadScreen> createState() =>
      _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends State<PrescriptionUploadScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final ProfileService _profileService = ProfileService();
  // Amélioration UX (audit Module 5, directive standing post-Module 3) :
  // upload_guidance_overlay.dart existait déjà dans le module mais n'était
  // référencé nulle part (grep : aucun import hors de sa propre définition)
  // — un écran de conseils entièrement construit et jamais montré à
  // l'utilisateur. Affiché une fois par visite de cet écran, avant la
  // première prise de photo.
  bool _hasShownGuidance = false;

  // C216 / D61 : officine destinataire, obligatoire avant l'envoi.
  String? _pharmacyId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
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
                      'Nouvelle ordonnance',
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
              child: _selectedImage == null
                  ? _buildUploadView(context)
                  : _buildPreviewView(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 80, color: context.palette.veil(0.24)),
          const SizedBox(height: 24),
          Text('Téléchargez votre ordonnance', style: context.text.heading3),
          const SizedBox(height: 8),
          Text(
            'Prenez une photo ou sélectionnez une image',
            style: context.text.body2,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImageWithGuidance(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Appareil photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.primary,
                  foregroundColor: context.palette.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _pickImageWithGuidance(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.palette.veil(0.24)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TertiaryButton(label: 'Annuler', onPressed: () => context.pop()),
        ],
      ),
    );
  }

  Widget _buildPreviewView(
    BuildContext context,
    PrescriptionProvider provider,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          DestinationPharmacyPicker(
            value: _pharmacyId,
            onChanged: (id) => setState(() => _pharmacyId = id),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedImage = null),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reprendre'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.palette.veil(0.24)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  // C239 : sans lecture automatique, simple envoi.
                  label: PilotConfig.aiPrescriptionOcr
                      ? 'Analyser l\'ordonnance'
                      : 'Envoyer l\'ordonnance',
                  isLoading:
                      provider.isProcessingOcr ||
                      provider.uploadStatus ==
                          PrescriptionUploadStatus.uploading,
                  onPressed: () async {
                    // Bug corrigé (audit Module 5, 29/08/2026) : cet écran
                    // envoyait un patientId ('patient_123') et un
                    // patientName ('Jean Dupont') en dur, quel que soit
                    // l'utilisateur réellement connecté. Au-delà de
                    // l'incohérence produit, 'patient_123' n'est pas un uuid
                    // valide : prescriptions.patient_id est de type uuid, et
                    // prescriptions_select_own (RLS) compare auth.uid() à
                    // patient_id — l'insertion échouait donc pour tout le
                    // monde en production (même défaut que le userId 'admin'
                    // en dur trouvé dans stock_adjustment_screen.dart au
                    // Module 4).
                    final pharmacyId = _pharmacyId;
                    if (pharmacyId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Choisissez l\'officine qui recevra l\'ordonnance.',
                          ),
                          backgroundColor: context.palette.warning,
                        ),
                      );
                      return;
                    }
                    final auth = context.read<AuthProvider>();
                    final patientId = auth.userId;
                    if (patientId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Vous devez être connecté pour déposer une ordonnance.',
                          ),
                          backgroundColor: context.palette.danger,
                        ),
                      );
                      return;
                    }
                    final fullName = await _profileService.getFullName(
                      patientId,
                    );
                    final patientName =
                        fullName ??
                        auth.userEmail ??
                        auth.userPhone ??
                        'Patient';
                    await provider.uploadPrescription(
                      _selectedImage!.path,
                      patientId,
                      patientName,
                      pharmacyId: pharmacyId,
                    );
                    if (provider.uploadStatus ==
                            PrescriptionUploadStatus.ready &&
                        context.mounted) {
                      if (PilotConfig.aiPrescriptionOcr) {
                        context.go('/prescriptions/preview');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ordonnance envoyée à l\'officine.'),
                          ),
                        );
                        context.go('/prescriptions');
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          if (provider.uploadStatus == PrescriptionUploadStatus.processing) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              PilotConfig.aiPrescriptionOcr
                  ? 'Analyse en cours...'
                  : 'Envoi en cours...',
              style: context.text.body2.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ],
          if (provider.uploadError != null) ...[
            const SizedBox(height: 16),
            // Le mode hors-ligne (directive standing, mode offline) n'est
            // pas une erreur — c'est une confirmation que l'ordonnance a
            // bien été prise en compte localement. La distinguer visuellement
            // d'un échec réel évite d'inquiéter le patient à tort.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (provider.isOffline
                            ? context.palette.warningStrong
                            : context.palette.danger)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      (provider.isOffline
                              ? context.palette.warningStrong
                              : context.palette.danger)
                          .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    provider.isOffline ? Icons.cloud_off : Icons.error_outline,
                    size: 18,
                    color: provider.isOffline
                        ? context.palette.warningStrong
                        : context.palette.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.uploadError!,
                      style: context.text.body2.copyWith(
                        color: provider.isOffline
                            ? context.palette.warningStrong
                            : context.palette.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImageWithGuidance(ImageSource source) async {
    if (_hasShownGuidance) {
      await _pickImage(source);
      return;
    }
    final shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          top: 16,
        ),
        child: UploadGuidanceOverlay(
          onContinue: () => Navigator.pop(sheetContext, true),
          onCancel: () => Navigator.pop(sheetContext, false),
        ),
      ),
    );
    _hasShownGuidance = true;
    if (shouldContinue == true) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      // Erreur silencieuse corrigée (audit Module 5, 29/08/2026) : un refus
      // de permission caméra/galerie laissait l'utilisateur devant un écran
      // inchangé, sans aucune explication.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'accéder à l\'image : $e'),
            backgroundColor: context.palette.danger,
          ),
        );
      }
    }
  }
}
