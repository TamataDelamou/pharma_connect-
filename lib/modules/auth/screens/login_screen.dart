import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/pilot/pilot_config.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/auth_provider.dart';
import '../widgets/phone_input_field.dart';
import '../../../core/theme/palette.dart';

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
                  Text('Connexion', style: context.text.heading2),
                  const SizedBox(height: 8),
                  Text(
                    PilotConfig.authEmailOnly
                        ? PilotConfig.authEmailOnlySubtitle
                        : 'Choisissez votre identifiant et le mode de réception',
                    style: context.text.body2,
                  ),
                  const SizedBox(height: 32),

                  // ===== CHOIX DE LA MÉTHODE =====
                  // C239 : un seul mode, pas de puce de choix.
                  if (!PilotConfig.authEmailOnly) ...[
                    _buildMethodChoiceChips(),
                    const SizedBox(height: 24),
                  ],

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
                      Text('Pas encore de compte ?', style: context.text.body2),
                      TertiaryButton(
                        label: 'S\'inscrire',
                        onPressed: () => context.go('/register'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ===== PIED DE CARTE =====
                  Divider(color: context.palette.veil(0.12), height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: context.palette.textFaded(0.6),
                      ),
                      const SizedBox(width: 4),
                      // Le Kernel GSG n'est pas branché (registre, D2) : pas
                      // de mention du Kernel ici.
                      Text(
                        'Connexion sécurisée',
                        style: context.text.micro.copyWith(
                          color: context.palette.textFaded(0.6),
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
        _buildChip(LoginMethod.emailCode, '📧 Code par e-mail'),
        // C239 : autres modes masqués pour le pilote (`PilotConfig`).
        if (PilotConfig.authMagicLink)
          _buildChip(LoginMethod.emailMagic, '🔗 Magic Link'),
        if (PilotConfig.authWhatsapp)
          _buildChip(LoginMethod.phoneWhatsapp, '💬 WhatsApp'),
        if (PilotConfig.authSms) _buildChip(LoginMethod.phoneSms, '📱 SMS'),
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
      selectedColor: context.palette.primary.withValues(alpha: 0.2),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: _selectedMethod == method
            ? context.palette.primary
            : context.palette.veil(0.24),
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
        color: context.palette.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.palette.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: context.palette.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.text.micro.copyWith(
                color: context.palette.textSecondary,
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
        return 'Recevoir le code';
      case LoginMethod.phoneWhatsapp:
        return 'Recevoir le code';
      case LoginMethod.emailMagic:
        return 'Recevoir le lien';
      case LoginMethod.emailCode:
        return 'Recevoir le code';
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
        SnackBar(
          content: Text('Erreur lors de l\'envoi. Vérifiez votre identifiant.'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }
}
