import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/auth_provider.dart';

class TwoFactorScreen extends StatefulWidget {
  final String userId;

  const TwoFactorScreen({super.key, required this.userId});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  int _resendCountdown = 60;
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
    _resendCountdown = 60;
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
                  const Row(
                    children: [
                      Text(
                        '◈',
                        style: TextStyle(
                          fontSize: 28,
                          color: PharmaConnectColors.accentCyan,
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
                            color: PharmaConnectColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      KernelBadge(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Authentification à deux facteurs',
                    style: PharmaConnectTypography.heading2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Un code de sécurité a été envoyé sur votre téléphone',
                    style: PharmaConnectTypography.body2,
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
                        style: PharmaConnectTypography.body2,
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
                          const SnackBar(
                            content: Text('Code invalide'),
                            backgroundColor: PharmaConnectColors.accentRed,
                          ),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);
                      // Simuler la vérification
                      await Future.delayed(const Duration(seconds: 1));
                      setState(() => _isLoading = false);

                      // Simuler une vérification réussie
                      if (context.mounted) {
                        context.go('/dashboard');
                      }
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
