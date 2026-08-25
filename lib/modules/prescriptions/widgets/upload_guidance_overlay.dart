import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class UploadGuidanceOverlay extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const UploadGuidanceOverlay({
    super.key,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PharmaConnectColors.primaryDeep.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
        border: Border.all(
          color: PharmaConnectColors.accentCyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_camera, color: PharmaConnectColors.accentCyan),
              SizedBox(width: 12),
              Text(
                'Conseils pour une bonne photo',
                style: PharmaConnectTypography.heading3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTip(
            icon: Icons.lightbulb,
            text: 'Choisissez un endroit bien éclairé',
            color: PharmaConnectColors.accentOrange,
          ),
          const SizedBox(height: 8),
          _buildTip(
            icon: Icons.center_focus_strong,
            text: 'Cadrez toute l\'ordonnance dans le viseur',
            color: PharmaConnectColors.accentCyan,
          ),
          const SizedBox(height: 8),
          _buildTip(
            icon: Icons.camera_alt,
            text: 'Assurez-vous que le texte est net et lisible',
            color: PharmaConnectColors.accentGreen,
          ),
          const SizedBox(height: 8),
          _buildTip(
            icon: Icons.photo_size_select_actual,
            text: 'Évitez les ombres et les reflets sur le document',
            color: PharmaConnectColors.accentPurple,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        PharmaConnectSpacing.radiusMd,
                      ),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        PharmaConnectSpacing.radiusMd,
                      ),
                    ),
                  ),
                  child: const Text('Compris, continuer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: PharmaConnectTypography.body2)),
      ],
    );
  }
}
