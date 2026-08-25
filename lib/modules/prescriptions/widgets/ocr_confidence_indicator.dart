import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class OcrConfidenceIndicator extends StatelessWidget {
  final double confidence;
  final double size;

  const OcrConfidenceIndicator({
    super.key,
    required this.confidence,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(confidence);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: confidence,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
            ),
            Column(
              children: [
                Text(
                  '${(confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  _getLabel(confidence),
                  style: PharmaConnectTypography.micro,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Confiance OCR', style: PharmaConnectTypography.label),
      ],
    );
  }

  Color _getColor(double confidence) {
    if (confidence >= 0.8) return PharmaConnectColors.accentGreen;
    if (confidence >= 0.6) return PharmaConnectColors.accentOrange;
    return PharmaConnectColors.accentRed;
  }

  String _getLabel(double confidence) {
    if (confidence >= 0.8) return 'Élevée';
    if (confidence >= 0.6) return 'Moyenne';
    return 'Faible';
  }
}
