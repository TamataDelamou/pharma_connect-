import 'package:flutter/material.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/palette.dart';

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
        color: context.palette.background.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
        border: Border.all(
          color: context.palette.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera, color: context.palette.primary),
              SizedBox(width: 12),
              Text(
                'Conseils pour une bonne photo',
                style: context.text.heading3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTip(
            context,
            icon: Icons.lightbulb,
            text: 'Choisissez un endroit bien éclairé',
            color: context.palette.warning,
          ),
          const SizedBox(height: 8),
          _buildTip(
            context,
            icon: Icons.center_focus_strong,
            text: 'Cadrez toute l\'ordonnance dans le viseur',
            color: context.palette.primary,
          ),
          const SizedBox(height: 8),
          _buildTip(
            context,
            icon: Icons.camera_alt,
            text: 'Assurez-vous que le texte est net et lisible',
            color: context.palette.success,
          ),
          const SizedBox(height: 8),
          _buildTip(
            context,
            icon: Icons.photo_size_select_actual,
            text: 'Évitez les ombres et les reflets sur le document',
            color: context.palette.secondary,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.palette.veil(0.24)),
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
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
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

  Widget _buildTip(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: context.text.body2)),
      ],
    );
  }
}
