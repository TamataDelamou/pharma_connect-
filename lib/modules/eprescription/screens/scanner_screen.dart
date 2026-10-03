import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../services/scanner_service.dart';
import '../services/eprescription_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ScannerService _scannerService = ScannerService();
  ScannedPrescription? _scanResult;
  Future<Uint8List>? _scanImageFuture;
  bool _isProcessing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
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
                      '📷 Scanner une ordonnance',
                      style: PharmaConnectTypography.heading2,
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
                  children: [
                    // Upload section
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1️⃣ Prenez une photo de l\'ordonnance',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Assurez-vous que le texte est bien lisible',
                            style: PharmaConnectTypography.body2,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessing
                                      ? null
                                      : () => _pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Appareil photo'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessing
                                      ? null
                                      : () => _pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Galerie'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_isProcessing)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text(
                                'Analyse en cours...',
                                style: PharmaConnectTypography.body2,
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_scanResult != null) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '2️⃣ Résultat du scan',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 8),
                            if (_scanResult!.imagePath != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder<Uint8List>(
                                  future: _scanImageFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                      );
                                    }
                                    return const SizedBox(
                                      height: 150,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Médicaments détectés :',
                              style: PharmaConnectTypography.label,
                            ),
                            if (_scanResult!.extractedItems.isEmpty)
                              const Text('Aucun médicament détecté')
                            else
                              ..._scanResult!.extractedItems.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.medication,
                                        size: 16,
                                        color: PharmaConnectColors.accentCyan,
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${item['name']} ${item['dosage']}'),
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    label: 'Créer la prescription',
                                    onPressed: () async {
                                      final service = EPrescriptionService();
                                      final prescription = await _scannerService
                                          .createFromScan(_scanResult!.id);
                                      if (context.mounted) {
                                        context.push(
                                          '/eprescription/${prescription.id}',
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TertiaryButton(
                                  label: 'Réessayer',
                                  onPressed: () {
                                    setState(() {
                                      _scanResult = null;
                                      _isProcessing = false;
                                      _error = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentRed.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PharmaConnectColors.accentRed.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: PharmaConnectColors.accentRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!)),
                          ],
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      // PRE-3 (audit Module 25, Étape 2/3, 30/08/2026) : appelait
      // directement `_scannerService._imagePicker`, un champ privé déclaré
      // dans un autre fichier (`scanner_service.dart`) — invisible ici par
      // construction (privacité Dart portée par le fichier, pas la classe),
      // ne pouvait pas compiler. Corrigé via la méthode publique dédiée
      // `ScannerService.pickImage()`.
      final image = await _scannerService.pickImage(source);
      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _error = null;
      });

      final result = await _scannerService.scanPrescription(
        patientId: SupabaseService().currentUser!.id,
        image: image,
      );

      setState(() {
        _scanResult = result;
        _scanImageFuture = result.imagePath != null
            ? _scannerService.downloadScanImage(result.imagePath!)
            : null;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }
}
