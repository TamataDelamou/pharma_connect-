import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../widgets/phone_input_field.dart';

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
    {'label': 'Régulateur / Institution', 'value': UserRole.regulateur},
  ];

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
                    'Créer un compte',
                    style: PharmaConnectTypography.heading2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rejoignez l\'infrastructure numérique de la santé',
                    style: PharmaConnectTypography.body2,
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
                    dropdownColor: PharmaConnectColors.primaryDeep,
                    style: PharmaConnectTypography.body1,
                    decoration: InputDecoration(
                      labelText: 'Je suis un(e) :',
                      labelStyle: PharmaConnectTypography.label,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PharmaConnectSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PharmaConnectSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PharmaConnectSpacing.radiusMd,
                        ),
                        borderSide: const BorderSide(
                          color: PharmaConnectColors.accentCyan,
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
                        child: Text(
                          role['label'],
                          style: PharmaConnectTypography.body1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedRole = value);
                    },
                  ),
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
                      _buildChip('Email (code)', 'emailCode'),
                      _buildChip('WhatsApp', 'phoneWhatsapp'),
                      _buildChip('SMS', 'phoneSms'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentOrange.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        PharmaConnectSpacing.radiusSm,
                      ),
                      border: Border.all(
                        color: PharmaConnectColors.accentOrange.withValues(
                          alpha: 0.2,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: PharmaConnectColors.accentOrange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Les comptes professionnels nécessitent une vérification de licence après activation.',
                            style: PharmaConnectTypography.micro.copyWith(
                              color: PharmaConnectColors.textSecondary,
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
                          const SnackBar(
                            content: Text('Erreur lors de l\'envoi.'),
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
                      const Text(
                        'Déjà un compte ?',
                        style: PharmaConnectTypography.body2,
                      ),
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
      selectedColor: PharmaConnectColors.accentCyan.withValues(alpha: 0.2),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: _selectedMethod == method
            ? PharmaConnectColors.accentCyan
            : Colors.white24,
      ),
    );
  }
}
