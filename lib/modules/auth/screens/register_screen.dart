import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/pilot/pilot_config.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../widgets/phone_input_field.dart';
import '../../../core/theme/palette.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  UserRole _selectedRole = UserRole.patient;
  String _selectedMethod = 'emailCode'; // phoneSms, phoneWhatsapp, emailCode
  String? _phoneE164;

  bool get _isPhoneMethod =>
      _selectedMethod == 'phoneSms' || _selectedMethod == 'phoneWhatsapp';

  final List<Map<String, dynamic>> _roles = [
    {'label': 'Patient', 'value': UserRole.patient},
    {'label': 'Pharmacien titulaire', 'value': UserRole.pharmacien},
    {'label': 'Grossiste répartiteur', 'value': UserRole.grossiste},
    {'label': 'Livreur', 'value': UserRole.livreur},
    {'label': 'Professionnel de santé', 'value': UserRole.professionnel},
    // C211 / D58 : pas d'auto-inscription comme régulateur ; les comptes
    // institutionnels sont créés et validés par GSG (admin_set_user_role).
  ];

  // C211 / D58 : rôles déclarés dont les droits ne s'ouvrent qu'après
  // vérification (officine validée, fiche professionnelle vérifiée ou
  // validation GSG).
  static const _rolesNeedingVerification = {
    UserRole.pharmacien,
    UserRole.grossiste,
    UserRole.livreur,
    UserRole.professionnel,
  };

  @override
  void dispose() {
    _nameController.dispose();
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
                  Text('Créer un compte', style: context.text.heading2),
                  const SizedBox(height: 8),
                  Text(
                    'Rejoignez l\'infrastructure numérique de la santé',
                    style: context.text.body2,
                  ),
                  const SizedBox(height: 24),

                  // Nom complet
                  GlassInput(
                    label: 'Nom complet',
                    hint: 'Dr. Jean Dupont',
                    controller: _nameController,
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: 16),

                  // Rôle
                  DropdownButtonFormField<UserRole>(
                    initialValue: _selectedRole,
                    dropdownColor: context.palette.background,
                    style: context.text.body1,
                    decoration: InputDecoration(
                      labelText: 'Je suis un(e) :',
                      labelStyle: context.text.label,
                      filled: true,
                      fillColor: context.palette.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PharmaConnectSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: context.palette.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PharmaConnectSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: context.palette.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PharmaConnectSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: context.palette.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem<UserRole>(
                        value: role['value'],
                        child: Text(role['label'], style: context.text.body1),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedRole = value);
                    },
                  ),
                  if (_rolesNeedingVerification.contains(_selectedRole)) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: context.palette.textSecondary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Votre compte professionnel sera activé après '
                            'vérification par GSG.',
                            style: context.text.micro,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Identifiant (téléphone ou email)
                  _isPhoneMethod
                      ? PhoneInputField(
                          onChanged: (e164) =>
                              setState(() => _phoneE164 = e164),
                        )
                      : GlassInput(
                          label: 'Adresse email',
                          hint: 'jean.dupont@example.com',
                          controller: _identifierController,
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                  const SizedBox(height: 12),

                  // Choix du mode de réception
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('Code par e-mail', 'emailCode'),
                      // C239 : autres modes masqués pour le pilote
                      // (`PilotConfig`).
                      if (PilotConfig.authWhatsapp)
                        _buildChip('WhatsApp', 'phoneWhatsapp'),
                      if (PilotConfig.authSms) _buildChip('SMS', 'phoneSms'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.palette.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        PharmaConnectSpacing.radiusSm,
                      ),
                      border: Border.all(
                        color: context.palette.warning.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: context.palette.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Les comptes professionnels nécessitent une vérification de licence après activation.',
                            style: context.text.micro.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    label: 'S\'inscrire',
                    isLoading: auth.isLoading,
                    onPressed: () async {
                      if (_nameController.text.isEmpty) return;
                      if (_isPhoneMethod) {
                        if (_phoneE164 == null) return;
                      } else if (_identifierController.text.isEmpty) {
                        return;
                      }

                      // Envoyer l'OTP avec la méthode choisie
                      bool success;
                      final identifier = _isPhoneMethod
                          ? _phoneE164!
                          : _identifierController.text.trim();
                      if (_selectedMethod == 'phoneSms') {
                        success = await auth.sendPhoneOtp(identifier, 'sms');
                      } else if (_selectedMethod == 'phoneWhatsapp') {
                        success = await auth.sendPhoneOtp(
                          identifier,
                          'whatsapp',
                        );
                      } else {
                        success = await auth.sendEmailOtp(identifier, false);
                      }

                      if (success && context.mounted) {
                        // On stocke les infos supplémentaires dans le provider
                        auth.setRole(_selectedRole);
                        // On passe à l'écran OTP avec l'identifiant ; nom/rôle
                        // ne seront écrits dans profiles qu'après vérification
                        // réussie du code (voir AuthProvider._persistProfile).
                        context.go(
                          '/otp',
                          extra: {
                            'identifier': identifier,
                            'method': _selectedMethod,
                            'fullName': _nameController.text.trim(),
                            'role': _selectedRole,
                          },
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de l\'envoi.'),
                            backgroundColor: context.palette.danger,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Déjà un compte ?', style: context.text.body2),
                      TertiaryButton(
                        label: 'Se connecter',
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

  Widget _buildChip(String label, String method) {
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
}
