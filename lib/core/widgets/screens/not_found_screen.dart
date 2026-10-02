import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../buttons/primary_button.dart';
import '../cards/glass_card.dart';

/// C231 : page affichée pour une route inconnue (errorBuilder du routeur).
/// Remplace la page par défaut de go_router, dont l'unique bouton menait à
/// `/`, route absente : l'utilisateur restait bloqué sur la page d'erreur.
class NotFoundScreen extends StatelessWidget {
  final bool isAuthenticated;

  const NotFoundScreen({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    final target = isAuthenticated ? '/dashboard' : '/login';
    final label = isAuthenticated
        ? 'Retour au tableau de bord'
        : 'Retour à la connexion';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 420,
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.explore_off,
                    size: 40,
                    color: PharmaConnectColors.accentCyan,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Page introuvable',
                    style: PharmaConnectTypography.heading2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cette page n\'existe pas ou n\'est pas encore disponible.',
                    style: PharmaConnectTypography.body2,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: label,
                    onPressed: () => context.go(target),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
