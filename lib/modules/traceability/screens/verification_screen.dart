import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_role.dart';
import '../providers/traceability_provider.dart';
import '../widgets/verification_result_card.dart';
import '../../../core/theme/palette.dart';

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
                      'Vérifier un produit',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 8),
            Text(
              'Scannez le code-barres ou saisissez le numéro de série',
              style: context.text.body2,
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
                          Icon(
                            Icons.qr_code_scanner,
                            size: 64,
                            color: context.palette.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toucher pour scanner',
                            style: context.text.body1.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.palette.primary,
                            ),
                          ),
                          Text(
                            'Scannez le code-barres ou le QR code du produit',
                            style: context.text.body2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ou saisie manuelle
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: context.palette.veil(0.24)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou saisissez manuellement',
                            style: context.text.micro,
                          ),
                        ),
                        Expanded(
                          child: Divider(color: context.palette.veil(0.24)),
                        ),
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
                            SnackBar(
                              content: Text(
                                'Veuillez saisir un numéro de série',
                              ),
                              backgroundColor: context.palette.danger,
                            ),
                          );
                          return;
                        }
                        // Correctif audit Module 12 (29/08/2026) : 'Pharmacien'
                        // était codé en dur, alors que ce même écran est
                        // accessible à tout utilisateur authentifié (patient
                        // compris, via ScanFloatingButton) — le libellé
                        // affiché sur le résultat mentait sur qui avait
                        // vérifié. verified_by (le uuid réel, colonne FK)
                        // n'est de toute façon jamais construit à partir de
                        // ce libellé (voir traceability_service.dart) ; il
                        // ne sert qu'à l'affichage.
                        final role = context.read<AuthProvider>().effectiveRole;
                        await provider.verifyProduct(
                          serialNumber: _serialController.text.trim(),
                          gtin: _gtinController.text.trim(),
                          verifiedBy: role?.label ?? 'Utilisateur',
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
                          color: context.palette.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.palette.danger.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Text(
                          provider.error!,
                          style: context.text.body2.copyWith(
                            color: context.palette.danger,
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

  // Correctif audit Module 12 (29/08/2026) : `rawValue.substring(0, 13)`
  // levait un RangeError (crash de l'écran, pas seulement un résultat
  // incorrect) pour tout code-barres dont la valeur brute faisait moins de
  // 13 caractères — trivialement atteignable (QR code de test, numéro de
  // série court, etc.). Tente en plus une lecture GS1 basique (AI(01) =
  // GTIN-14, AI(21) = numéro de série), le format que le cahier attend
  // réellement pour un Datamatrix pharmaceutique, avant de retomber sur
  // l'ancienne heuristique (désormais sans risque de crash) si le code
  // scanné n'est pas au format GS1.
  static Map<String, String> _parseBarcode(String raw) {
    final gtinMatch = RegExp(r'01(\d{14})').firstMatch(raw);
    final serialMatch = RegExp(r'21(.+)$', dotAll: true).firstMatch(raw);
    if (gtinMatch != null) {
      var gtin = gtinMatch.group(1)!;
      // GTIN-14 avec un zéro de bourrage en tête -> EAN-13 usuel de ce
      // catalogue (voir traceable_batches.gtin, ex. '0032456789012').
      if (gtin.startsWith('0')) gtin = gtin.substring(1);
      final serial = serialMatch != null
          ? serialMatch.group(1)!.split(RegExp(r'[\x00-\x1f]')).first.trim()
          : raw;
      return {'serial': serial, 'gtin': gtin};
    }
    // Pas un GS1 reconnu : traiter la valeur brute comme numéro de série,
    // et n'en dériver un GTIN que si elle est assez longue pour ça.
    return {
      'serial': raw,
      'gtin': raw.length >= 13 ? raw.substring(0, 13) : '',
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // C226 : titre et retour fournis par AppShell (route_titles.dart), plus
    // de barre propre à l'écran.
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              final raw = barcode.rawValue;
              if (raw != null && raw.isNotEmpty) {
                Navigator.pop(context, _parseBarcode(raw));
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: context.palette.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
