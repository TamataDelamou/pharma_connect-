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
import '../widgets/phone_input_field.dart';

enum LoginMethod { emailCode, emailMagic, phoneWhatsapp, phoneSms }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  LoginMethod _selectedMethod = LoginMethod.emailCode;
  String? _phoneE164;

  bool get _isPhoneMethod =>
      _selectedMethod == LoginMethod.phoneSms ||
      _selectedMethod == LoginMethod.phoneWhatsapp;

  @override
  void dispose() {
    _identifierController.dispose();
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
            width: 480,
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
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
                    'Connexion',
                    style: PharmaConnectTypography.heading2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choisissez votre identifiant et le mode de réception',
                    style: PharmaConnectTypography.body2,
                  ),
                  const SizedBox(height: 32),

                  // ===== CHOIX DE LA MÉTHODE =====
                  _buildMethodChoiceChips(),
                  const SizedBox(height: 24),

                  // ===== CHAMP IDENTIFIANT =====
                  _isPhoneMethod
                      ? PhoneInputField(
                          onChanged: (e164) =>
                              setState(() => _phoneE164 = e164),
                        )
                      : GlassInput(
                          label: _getIdentifierLabel(),
                          hint: _getIdentifierHint(),
                          controller: _identifierController,
                          prefixIcon: _getIdentifierIcon(),
                          keyboardType: _getKeyboardType(),
                        ),
                  const SizedBox(height: 8),

                  // ===== INFORMATION COMPLÉMENTAIRE =====
                  _buildMethodInfo(),
                  const SizedBox(height: 24),

                  // ===== BOUTON D'ENVOI =====
                  PrimaryButton(
                    label: _getButtonLabel(),
                    isLoading: auth.isLoading,
                    onPressed: () async {
                      if (_isPhoneMethod) {
                        if (_phoneE164 == null) return;
                      } else if (_identifierController.text.isEmpty) {
                        return;
                      }
                      await _handleSendOtp(auth);
                    },
                  ),
                  const SizedBox(height: 16),

                  // ===== LIEN INSCRIPTION =====
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Pas encore de compte ?',
                        style: PharmaConnectTypography.body2,
                      ),
                      TertiaryButton(
                        label: 'S\'inscrire',
                        onPressed: () => context.go('/register'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ===== FOOTER KERNEL =====
                  const Divider(color: Colors.white12, height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Authentification sécurisée via GSG Kernel',
                        style: PharmaConnectTypography.micro.copyWith(
                          color: PharmaConnectColors.textSecondary.withValues(
                            alpha: 0.6,
                          ),
                        ),
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

  Widget _buildMethodChoiceChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(LoginMethod.emailCode, '📧 Code OTP'),
        _buildChip(LoginMethod.emailMagic, '🔗 Magic Link'),
        _buildChip(LoginMethod.phoneWhatsapp, '💬 WhatsApp'),
        _buildChip(LoginMethod.phoneSms, '📱 SMS'),
      ],
    );
  }

  Widget _buildChip(LoginMethod method, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedMethod == method,
      onSelected: (selected) {
        if (selected) setState(() => _selectedMethod = method);
      },
      selectedColor: PharmaConnectColors.accentCyan.withValues(alpha: 0.2),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: _selectedMethod == method
            ? PharmaConnectColors.accentCyan
            : Colors.white24,
      ),
    );
  }

  String _getIdentifierLabel() {
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
      case LoginMethod.phoneWhatsapp:
        return 'Numéro de téléphone';
      case LoginMethod.emailMagic:
      case LoginMethod.emailCode:
        return 'Adresse email';
    }
  }

  String _getIdentifierHint() {
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
      case LoginMethod.phoneWhatsapp:
        return '+224612345678';
      case LoginMethod.emailMagic:
      case LoginMethod.emailCode:
        return 'jean.dupont@example.com';
    }
  }

  IconData _getIdentifierIcon() {
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
        return Icons.sms;
      case LoginMethod.phoneWhatsapp:
        return Icons.chat;
      case LoginMethod.emailMagic:
        return Icons.link;
      case LoginMethod.emailCode:
        return Icons.email;
    }
  }

  TextInputType _getKeyboardType() {
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
      case LoginMethod.phoneWhatsapp:
        return TextInputType.phone;
      case LoginMethod.emailMagic:
      case LoginMethod.emailCode:
        return TextInputType.emailAddress;
    }
  }

  Widget _buildMethodInfo() {
    String message;
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
        message = 'Un code à 6 chiffres vous sera envoyé par SMS.';
        break;
      case LoginMethod.phoneWhatsapp:
        message = 'Un code à 6 chiffres vous sera envoyé sur WhatsApp.';
        break;
      case LoginMethod.emailMagic:
        message = 'Un lien de connexion vous sera envoyé par email.';
        break;
      case LoginMethod.emailCode:
        message = 'Un code à 6 chiffres vous sera envoyé par email.';
        break;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PharmaConnectColors.accentCyan.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PharmaConnectColors.accentCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: PharmaConnectColors.accentCyan,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: PharmaConnectTypography.micro.copyWith(
                color: PharmaConnectColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonLabel() {
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
        return 'Envoyer le code par SMS';
      case LoginMethod.phoneWhatsapp:
        return 'Envoyer le code par WhatsApp';
      case LoginMethod.emailMagic:
        return 'Envoyer le lien de connexion';
      case LoginMethod.emailCode:
        return 'Envoyer le code par email';
    }
  }

  Future<void> _handleSendOtp(AuthProvider auth) async {
    final identifier = _isPhoneMethod
        ? _phoneE164!
        : _identifierController.text.trim();
    bool success;

    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
        success = await auth.sendPhoneOtp(identifier, 'sms');
        break;
      case LoginMethod.phoneWhatsapp:
        success = await auth.sendPhoneOtp(identifier, 'whatsapp');
        break;
      case LoginMethod.emailMagic:
        success = await auth.sendEmailOtp(identifier, true);
        break;
      case LoginMethod.emailCode:
        success = await auth.sendEmailOtp(identifier, false);
        break;
    }

    if (!mounted) return;

    if (success) {
      context.go(
        '/otp',
        extra: {'identifier': identifier, 'method': _selectedMethod.name},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi. Vérifiez votre identifiant.'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}
