import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../providers/search_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.code128, BarcodeFormat.code39],
  );
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fond noir et textes clairs dans les deux thèmes, caméra active ou
    // refusée : l'écran utilise la palette sombre.
    return Theme(
      data: PharmaConnectAppTheme.dark(),
      child: Builder(builder: _buildScanner),
    );
  }

  Widget _buildScanner(BuildContext context) {
    return Scaffold(
      backgroundColor: PharmaConnectFixedColors.cameraBackdrop,
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null && !_isLoading) {
                _handleBarcode(barcode.rawValue!, context);
              }
            },
          ),

          // Overlay
          _buildOverlay(context),

          // Loading
          if (_isLoading) ...[
            Container(
              color: context.palette.overlay,
              child: Center(
                child: CircularProgressIndicator(
                  color: context.palette.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Column(
      children: [
        // En-tête
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: PharmaConnectFixedColors.onCamera,
                  ),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scanner un code-barres',
                    style: TextStyle(
                      color: PharmaConnectFixedColors.onCamera,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const KernelBadge(),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Zone de scan
        Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: context.palette.primary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: context.palette.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Positionnez le code-barres dans le cadre',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PharmaConnectFixedColors.onCamera,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const Spacer(),

        // Indicateurs
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flash_on,
                    color: PharmaConnectFixedColors.onCameraMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _controller.toggleTorch(),
                    child: Text(
                      'Activer la lampe',
                      style: TextStyle(
                        color: PharmaConnectFixedColors.onCameraMuted,
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: context.palette.danger, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _handleBarcode(String code, BuildContext context) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<SearchProvider>();
      await provider.scanBarcode(code);

      if (provider.scannedProduct != null && context.mounted) {
        context.go('/product/${provider.scannedProduct!.id}');
      } else if (context.mounted) {
        setState(() {
          _error = 'Aucun produit trouvé pour ce code-barres';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du scan';
        _isLoading = false;
      });
    }
  }
}
