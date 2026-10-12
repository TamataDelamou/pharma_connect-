import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/palette.dart';

/// C256 : QR code de retrait, lisible dans les deux thèmes.
///
/// Modules noirs sur fond blanc, indépendants du thème : un lecteur a besoin
/// de ce contraste, et le fond suivait la couleur du texte (presque noir en
/// thème clair : QR illisible). La marge blanche fait 4 modules, la zone de
/// silence exigée autour d'un QR code, calculée pour le plus petit QR code
/// (21 modules, celui du code de retrait à 6 caractères).
class PickupQrCode extends StatelessWidget {
  /// Contenu du QR code (code de retrait de la réservation).
  final String data;

  /// Côté du carré blanc, marge comprise.
  final double extent;

  const PickupQrCode({super.key, required this.data, required this.extent});

  /// Part du côté occupée par chaque marge : 4 modules sur 21 + 2 × 4.
  static const double marginRatio = 4 / 29;

  @override
  Widget build(BuildContext context) {
    final margin = extent * marginRatio;
    return Container(
      width: extent,
      height: extent,
      padding: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: PharmaConnectFixedColors.qrBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: extent - 2 * margin,
        padding: EdgeInsets.zero,
        gapless: false,
        backgroundColor: PharmaConnectFixedColors.qrBackground,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: PharmaConnectFixedColors.qrModule,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: PharmaConnectFixedColors.qrModule,
        ),
      ),
    );
  }
}
