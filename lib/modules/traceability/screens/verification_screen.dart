import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/traceability_provider.dart';
import '../widgets/verification_result_card.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _serialController = TextEditingController();
  final _gtinController = TextEditingController();

  @override
  void dispose() {
    _serialController.dispose();
    _gtinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TraceabilityProvider>();

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
                    'Vérifier un produit',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Scannez le code-barres ou saisissez le numéro de série',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Bouton de scan
                    GlassCard(
                      onTap: () => _startScanning(context),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            size: 64,
                            color: PharmaConnectColors.accentCyan,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toucher pour scanner',
                            style: PharmaConnectTypography.body1.copyWith(
                              fontWeight: FontWeight.w600,
                              color: PharmaConnectColors.accentCyan,
                            ),
                          ),
                          const Text(
                            'Scannez le code-barres ou le QR code du produit',
                            style: PharmaConnectTypography.body2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ou saisie manuelle
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou saisissez manuellement',
                            style: PharmaConnectTypography.micro,
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    GlassInput(
                      label: 'Numéro de série',
                      hint: 'Ex: SN-DOL-001-2024',
                      controller: _serialController,
                      prefixIcon: Icons.qr_code,
                    ),
                    const SizedBox(height: 12),
                    GlassInput(
                      label: 'GTIN (code-barres)',
                      hint: 'Ex: 0032456789012',
                      controller: _gtinController,
                      prefixIcon: Icons.qr_code_2,
                    ),
                    const SizedBox(height: 16),

                    PrimaryButton(
                      label: 'Vérifier',
                      isLoading: provider.isLoading,
                      onPressed: () async {
                        if (_serialController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Veuillez saisir un numéro de série',
                              ),
                              backgroundColor: PharmaConnectColors.accentRed,
                            ),
                          );
                          return;
                        }
                        await provider.verifyProduct(
                          serialNumber: _serialController.text.trim(),
                          gtin: _gtinController.text.trim(),
                          verifiedBy: 'Pharmacien',
                        );
                      },
                    ),

                    // Résultat
                    if (provider.verificationResult != null) ...[
                      const SizedBox(height: 16),
                      VerificationResultCard(
                        result: provider.verificationResult!,
                      ),
                    ],

                    if (provider.error != null) ...[
                      const SizedBox(height: 12),
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
                        child: Text(
                          provider.error!,
                          style: PharmaConnectTypography.body2.copyWith(
                            color: PharmaConnectColors.accentRed,
                          ),
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

  void _startScanning(BuildContext context) async {
    // Naviguer vers l'écran de scan
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _BarcodeScannerPage()),
    );

    if (result != null) {
      setState(() {
        _serialController.text = result['serial'] ?? '';
        _gtinController.text = result['gtin'] ?? '';
      });
    }
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner le produit'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                // Traitement du code-barres
                // Dans la réalité, on extrairait le GTIN et le numéro de série
                Navigator.pop(context, {
                  'serial': barcode.rawValue,
                  'gtin': barcode.rawValue?.substring(0, 13) ?? '',
                });
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: PharmaConnectColors.accentCyan,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
