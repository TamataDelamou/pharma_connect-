import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/palette.dart';

class TwoFactorScreen extends StatefulWidget {
  final String userId;

  const TwoFactorScreen({super.key, required this.userId});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  int _resendCountdown = 180;
  bool _isResendEnabled = true;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Simuler l'envoi du code 2FA
    _send2FACode();
  }

  void _send2FACode() {
    // Dans la réalité, appeler le service d'envoi de code 2FA
    // (email, SMS, application authenticator)
  }

  void _startCountdown() {
    _isResendEnabled = false;
    _resendCountdown = 180;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown == 0) _isResendEnabled = true;
        });
      }
      return _resendCountdown > 0;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SizedBox(
            width: 420,
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '◈',
                        style: TextStyle(
                          fontSize: 28,
                          color: context.palette.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PHARMACONNECT',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.palette.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      KernelBadge(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Authentification à deux facteurs',
                    style: context.text.heading2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Un code de sécurité a été envoyé sur votre téléphone',
                    style: context.text.body2,
                  ),
                  const SizedBox(height: 32),
                  GlassInput(
                    label: 'Code de vérification',
                    hint: '• • • • • •',
                    controller: _codeController,
                    prefixIcon: Icons.security,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isResendEnabled
                            ? 'Vous n\'avez pas reçu le code ?'
                            : 'Renvoyer dans $_resendCountdown s',
                        style: context.text.body2,
                      ),
                      TextButton(
                        onPressed: _isResendEnabled
                            ? () {
                                _send2FACode();
                                _startCountdown();
                              }
                            : null,
                        child: const Text('Renvoyer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Vérifier et continuer',
                    isLoading: _isLoading || auth.isLoading,
                    onPressed: () async {
                      if (_codeController.text.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Code invalide'),
                            backgroundColor: context.palette.danger,
                          ),
                        );
                        return;
                      }

                      // Audit Module 1 (29/08/2026) : ce bouton acceptait
                      // auparavant n'importe quelle saisie de 6 chiffres
                      // comme "vérifiée" (délai simulé, succès automatique).
                      // Un écran de sécurité qui ne vérifie rien est pire que
                      // son absence : il donne une fausse assurance sur des
                      // comptes que le cahier classe justement "2FA
                      // obligatoire" (pharmacie, grossiste, admin). Aucun
                      // fournisseur SMS/email n'est configuré pour un second
                      // facteur indépendant — même blocage déjà documenté
                      // pour l'OTP principal (rapport Étape 1, §1.3 point 4)
                      // — donc plutôt qu'une vérification simulée, un
                      // blocage honnête en attendant. Cet écran n'est de
                      // toute façon invoqué par aucun flux actuel (voir le
                      // correctif du redirect dans app_router.dart).
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Authentification à deux facteurs temporairement '
                            'indisponible (fournisseur SMS/email non '
                            'configuré). Contactez le support.',
                          ),
                          backgroundColor: context.palette.warning,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Retour à la connexion'),
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
