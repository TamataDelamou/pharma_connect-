import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../providers/prescription_provider.dart';

class PrescriptionUploadScreen extends StatefulWidget {
  const PrescriptionUploadScreen({super.key});

  @override
  State<PrescriptionUploadScreen> createState() =>
      _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends State<PrescriptionUploadScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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
                    'Nouvelle ordonnance',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
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
          const Icon(Icons.upload_file, size: 80, color: Colors.white24),
          const SizedBox(height: 24),
          const Text(
            'Téléchargez votre ordonnance',
            style: PharmaConnectTypography.heading3,
          ),
          const SizedBox(height: 8),
          const Text(
            'Prenez une photo ou sélectionnez une image',
            style: PharmaConnectTypography.body2,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Appareil photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PharmaConnectColors.accentCyan,
                  foregroundColor: PharmaConnectColors.textOnAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedImage = null),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reprendre'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Analyser l\'ordonnance',
                  isLoading:
                      provider.isProcessingOcr ||
                      provider.uploadStatus ==
                          PrescriptionUploadStatus.uploading,
                  onPressed: () async {
                    // Simuler l'ID patient
                    const patientId = 'patient_123';
                    const patientName = 'Jean Dupont';
                    await provider.uploadPrescription(
                      _selectedImage!.path,
                      patientId,
                      patientName,
                    );
                    if (provider.uploadStatus ==
                            PrescriptionUploadStatus.ready &&
                        context.mounted) {
                      context.go('/prescriptions/preview');
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
              'Analyse en cours...',
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.textSecondary,
              ),
            ),
          ],
          if (provider.uploadError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PharmaConnectColors.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PharmaConnectColors.accentRed.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                provider.uploadError!,
                style: PharmaConnectTypography.body2.copyWith(
                  color: PharmaConnectColors.accentRed,
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
      // handle error
    }
  }
}
