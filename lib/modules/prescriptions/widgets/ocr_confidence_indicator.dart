import 'package:flutter/material.dart';
import '../../../core/theme/palette.dart';

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
    final color = _getColor(context, confidence);

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
                backgroundColor: context.palette.border,
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
                Text(_getLabel(confidence), style: context.text.micro),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Confiance OCR', style: context.text.label),
      ],
    );
  }

  Color _getColor(BuildContext context, double confidence) {
    if (confidence >= 0.8) return context.palette.success;
    if (confidence >= 0.6) return context.palette.warning;
    return context.palette.danger;
  }

  String _getLabel(double confidence) {
    if (confidence >= 0.8) return 'Élevée';
    if (confidence >= 0.6) return 'Moyenne';
    return 'Faible';
  }
}
