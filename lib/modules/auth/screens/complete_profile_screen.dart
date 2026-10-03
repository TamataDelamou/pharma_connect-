import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../../../core/widgets/layout/responsive.dart';
import '../providers/auth_provider.dart';
import '../widgets/phone_input_field.dart';

/// C228 : un compte créé depuis l'écran de connexion n'a pas de nom
/// (`profiles.full_name` vide), l'écran de connexion ne le demandant pas.
/// Cet écran le demande une fois après la connexion. « Plus tard » mène au
/// tableau de bord ; l'écran revient à la connexion suivante tant que le nom
/// est vide.
///
/// Redirection posée sur la route /dashboard (app_router.dart).
String? completeProfileRedirect(BuildContext context) =>
    context.read<AuthProvider>().needsProfileCompletion
    ? '/complete-profile'
    : null;

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  // Numéro normalisé E.164 par PhoneInputField, null s'il est vide ou
  // incomplet (le téléphone est facultatif).
  String? _phoneE164;
  bool _nameMissing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(AuthProvider auth) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    setState(() => _nameMissing = false);
    final saved = await auth.completeProfile(fullName: name, phone: _phoneE164);
    if (!mounted) return;
    if (saved) {
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enregistrement impossible. Réessayez.'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: screenPadding(context, wide: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Complétez votre profil',
                    style: PharmaConnectTypography.heading2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Votre nom apparaît sur vos ordonnances et vos '
                    'réservations.',
                    style: PharmaConnectTypography.body2,
                  ),
                  const SizedBox(height: 24),
                  GlassInput(
                    label: 'Nom complet',
                    hint: 'Prénom et nom',
                    controller: _nameController,
                    prefixIcon: Icons.person,
                    isError: _nameMissing,
                    errorText: _nameMissing ? 'Le nom est obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Téléphone (facultatif)',
                    style: PharmaConnectTypography.label,
                  ),
                  const SizedBox(height: 8),
                  PhoneInputField(
                    onChanged: (e164) => setState(() => _phoneE164 = e164),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Enregistrer',
                    isLoading: auth.isLoading,
                    onPressed: () => _save(auth),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TertiaryButton(
                      label: 'Plus tard',
                      onPressed: () {
                        auth.skipProfileCompletion();
                        context.go('/dashboard');
                      },
                    ),
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
