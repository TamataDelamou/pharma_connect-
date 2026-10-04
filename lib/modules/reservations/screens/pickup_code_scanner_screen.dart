import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';

/// C243 : lecture du QR de retrait présenté par le patient. Rend le code lu
/// (`Navigator.pop`) ; le serveur seul décide s'il est le bon.
class PickupCodeScannerScreen extends StatefulWidget {
  const PickupCodeScannerScreen({super.key});

  @override
  State<PickupCodeScannerScreen> createState() =>
      _PickupCodeScannerScreenState();
}

class _PickupCodeScannerScreenState extends State<PickupCodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fond noir et textes clairs dans les deux thèmes, comme le scanner de
    // codes-barres.
    return Theme(
      data: PharmaConnectAppTheme.dark(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: PharmaConnectFixedColors.cameraBackdrop,
          body: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  if (_done || capture.barcodes.isEmpty) return;
                  final value = capture.barcodes.first.rawValue?.trim();
                  if (value == null || value.isEmpty) return;
                  _done = true;
                  Navigator.of(context).pop(value);
                },
              ),
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scanner le QR du patient',
                          style: TextStyle(
                            color: PharmaConnectFixedColors.onCamera,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.palette.primary,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
