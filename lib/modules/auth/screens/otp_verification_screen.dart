import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // Délai avant de pouvoir redemander un code (3 minutes). Le code lui-même
  // reste valable 1 heure (mailer_otp_exp = 3600) ; le serveur refuse de
  // toute façon un nouvel envoi moins de 60 s après le précédent (429).
  static const _resendDelaySeconds = 180;

  final _otpController = TextEditingController();
  bool _isResendEnabled = true;
  int _resendCountdown = _resendDelaySeconds;

  late String _identifier;
  late String _method;
  String? _fullName;
  UserRole? _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _identifier = args?['identifier'] ?? '';
    _method = args?['method'] ?? 'phoneSms';
    // Présents seulement quand on vient de l'inscription (register_screen.dart) ;
    // absents pour une simple connexion.
    _fullName = args?['fullName'] as String?;
    _role = args?['role'] as UserRole?;
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _isResendEnabled = false;
    _resendCountdown = _resendDelaySeconds;
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

  // Renvoie un code par le même canal que la demande initiale (login_screen
  // et register_screen transmettent la méthode dans `extra`).
  Future<void> _resendCode(AuthProvider auth) async {
    final bool sent;
    if (_method == 'phoneSms') {
      sent = await auth.sendPhoneOtp(_identifier, 'sms');
    } else if (_method == 'phoneWhatsapp') {
      sent = await auth.sendPhoneOtp(_identifier, 'whatsapp');
    } else {
      sent = await auth.sendEmailOtp(_identifier, false);
    }
    if (!mounted) return;
    if (sent) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Un nouveau code a été envoyé.')),
      );
    } else {
      final error = auth.error ?? '';
      final tooSoon =
          error.contains('over_email_send_rate_limit') ||
          error.contains('over_sms_send_rate_limit') ||
          error.contains('429');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tooSoon
                ? 'Veuillez patienter un instant avant de redemander un code.'
                : 'Erreur lors de l\'envoi du code.',
          ),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

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
                    'Vérification',
                    style: PharmaConnectTypography.heading2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Un code à 6 chiffres a été envoyé à ${_identifier.isEmpty ? 'votre identifiant' : _identifier}.',
                    style: PharmaConnectTypography.body2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Le code reste valable 1 heure.',
                    style: PharmaConnectTypography.body2,
                  ),
                  const SizedBox(height: 32),
                  GlassInput(
                    label: 'Code à 6 chiffres',
                    hint: '• • • • • •',
                    controller: _otpController,
                    prefixIcon: Icons.sms,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isResendEnabled
                            ? 'Vous n\'avez pas reçu le code ?'
                            : 'Renvoyer dans $_resendCountdown s',
                        style: PharmaConnectTypography.body2,
                      ),
                      TertiaryButton(
                        label: 'Renvoyer',
                        isDisabled: !_isResendEnabled,
                        onPressed: _isResendEnabled && !auth.isLoading
                            ? () => _resendCode(auth)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Vérifier et se connecter',
                    isLoading: auth.isLoading,
                    onPressed: () async {
                      // Un code copié depuis l'e-mail arrive souvent avec un
                      // espace ou un retour à la ligne : on ne garde que les
                      // chiffres, et on prévient au lieu d'ignorer le clic.
                      final code = _otpController.text.replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      if (code.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Saisissez les 6 chiffres du code reçu.',
                            ),
                            backgroundColor: PharmaConnectColors.accentRed,
                          ),
                        );
                        return;
                      }
                      bool success;
                      // Déterminer le type de vérification selon la méthode
                      if (_method == 'phoneSms' || _method == 'phoneWhatsapp') {
                        success = await auth.verifyPhoneOtp(
                          _identifier,
                          code,
                          fullName: _fullName,
                          role: _role,
                        );
                      } else {
                        success = await auth.verifyEmailOtp(
                          _identifier,
                          code,
                          fullName: _fullName,
                          role: _role,
                        );
                      }
                      if (success && context.mounted) {
                        // RG-AUT-01 (audit Module 1, 29/08/2026) : un
                        // pharmacien sans officine rattachée passe par la
                        // vérification de licence avant le tableau de bord.
                        context.go(
                          auth.needsLicenseVerification
                              ? '/license-verification'
                              : '/dashboard',
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code invalide ou expiré.'),
                            backgroundColor: PharmaConnectColors.accentRed,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TertiaryButton(
                        label: '← Retour à la connexion',
                        onPressed: () => context.go('/login'),
                      ),
                    ],
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
