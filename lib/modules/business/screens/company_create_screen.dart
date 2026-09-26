import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../providers/business_provider.dart';
import '../models/business_company.dart';

class CompanyCreateScreen extends StatefulWidget {
  final String? companyId;

  const CompanyCreateScreen({super.key, this.companyId});

  @override
  State<CompanyCreateScreen> createState() => _CompanyCreateScreenState();
}

class _CompanyCreateScreenState extends State<CompanyCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _contactPersonNameController = TextEditingController();
  final _contactPersonPhoneController = TextEditingController();
  final _contactPersonEmailController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'wholesaler';
  String _selectedStatus = 'active';
  bool _isLoading = false;
  bool _prefilled = false;

  bool get _isEditing => widget.companyId != null;

  static const List<Map<String, String>> _companyTypes = [
    {'value': 'hospital', 'label': '🏥 Hôpital'},
    {'value': 'clinic', 'label': '🏥 Clinique'},
    {'value': 'wholesaler', 'label': '📦 Grossiste'},
    {'value': 'laboratory', 'label': '🔬 Laboratoire'},
    {'value': 'pharmacy_chain', 'label': '💊 Chaîne de pharmacies'},
    {'value': 'insurance', 'label': '🛡️ Assurance'},
    {'value': 'other', 'label': '📋 Autre'},
  ];

  static const List<Map<String, String>> _companyStatuses = [
    {'value': 'active', 'label': '✅ Actif'},
    {'value': 'inactive', 'label': '⛔ Inactif'},
    {'value': 'pending', 'label': '⏳ En attente'},
    {'value': 'suspended', 'label': '🚫 Suspendu'},
    {'value': 'archived', 'label': '📦 Archivé'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BusinessProvider>().loadCompany(widget.companyId!);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEditing && !_prefilled) {
      final company = context.watch<BusinessProvider>().selectedCompany;
      if (company != null && company.id == widget.companyId) {
        _prefilled = true;
        _nameController.text = company.name;
        _legalNameController.text = company.legalName ?? '';
        _registrationNumberController.text = company.registrationNumber ?? '';
        _taxIdController.text = company.taxId ?? '';
        _addressController.text = company.address ?? '';
        _cityController.text = company.city ?? '';
        _countryController.text = company.country ?? '';
        _phoneController.text = company.phone ?? '';
        _emailController.text = company.email ?? '';
        _websiteController.text = company.website ?? '';
        _contactPersonNameController.text = company.contactPersonName ?? '';
        _contactPersonPhoneController.text = company.contactPersonPhone ?? '';
        _contactPersonEmailController.text = company.contactPersonEmail ?? '';
        _notesController.text = company.notes ?? '';
        _selectedType = company.type;
        _selectedStatus = company.status;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _registrationNumberController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _contactPersonNameController.dispose();
    _contactPersonPhoneController.dispose();
    _contactPersonEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && context.watch<BusinessProvider>().isLoading && !_prefilled) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: PharmaConnectColors.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEditing
                          ? '🤝 Modifier le partenaire'
                          : '🤝 Nouveau partenaire',
                      style: PharmaConnectTypography.heading2,
                    ),
                  ),
                  const KernelBadge(),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GlassInput(
                              label: 'Nom',
                              hint: 'Ex: Grossiste Guinée SA',
                              controller: _nameController,
                              prefixIcon: Icons.business,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un nom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Type',
                                border: OutlineInputBorder(),
                              ),
                              items: _companyTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type['value'],
                                  child: Text(type['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedType = value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // RG non tranchée par le cahier : le statut n'est
                            // exposé qu'en édition (le backend le défaute déjà
                            // à 'pending' à la création, voir C149 pour la
                            // dette cosmétique associée côté service).
                            if (_isEditing) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Statut',
                                  border: OutlineInputBorder(),
                                ),
                                items: _companyStatuses.map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status['value'],
                                    child: Text(status['label']!),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedStatus = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                            ],

                            GlassInput(
                              label: 'Raison sociale (optionnel)',
                              controller: _legalNameController,
                              prefixIcon: Icons.badge,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'N° Immatriculation (optionnel)',
                              controller: _registrationNumberController,
                              prefixIcon: Icons.numbers,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'N° Fiscal (optionnel)',
                              controller: _taxIdController,
                              prefixIcon: Icons.receipt_long,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Adresse (optionnel)',
                              controller: _addressController,
                              prefixIcon: Icons.location_on,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Ville (optionnel)',
                              controller: _cityController,
                              prefixIcon: Icons.location_city,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Pays (optionnel)',
                              controller: _countryController,
                              prefixIcon: Icons.public,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Téléphone (optionnel)',
                              controller: _phoneController,
                              prefixIcon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Email (optionnel)',
                              controller: _emailController,
                              prefixIcon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Site web (optionnel)',
                              controller: _websiteController,
                              prefixIcon: Icons.language,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Contact - Nom (optionnel)',
                              controller: _contactPersonNameController,
                              prefixIcon: Icons.person,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Contact - Téléphone (optionnel)',
                              controller: _contactPersonPhoneController,
                              prefixIcon: Icons.phone_in_talk,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Contact - Email (optionnel)',
                              controller: _contactPersonEmailController,
                              prefixIcon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Notes (optionnel)',
                              controller: _notesController,
                              prefixIcon: Icons.notes,
                              keyboardType: TextInputType.multiline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: _isLoading
                            ? (_isEditing ? 'Mise à jour...' : 'Création...')
                            : (_isEditing
                                  ? 'Mettre à jour'
                                  : 'Créer le partenaire'),
                        isLoading: _isLoading,
                        onPressed: _saveCompany,
                      ),
                      const SizedBox(height: 8),
                      TertiaryButton(
                        label: 'Annuler',
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now().toUtc();
    final existing = _isEditing
        ? context.read<BusinessProvider>().selectedCompany
        : null;

    final company = BusinessCompany(
      id: widget.companyId ?? '',
      name: _nameController.text.trim(),
      type: _selectedType,
      status: _isEditing ? _selectedStatus : 'active',
      legalName: _legalNameController.text.trim().isNotEmpty
          ? _legalNameController.text.trim()
          : null,
      registrationNumber: _registrationNumberController.text.trim().isNotEmpty
          ? _registrationNumberController.text.trim()
          : null,
      taxId: _taxIdController.text.trim().isNotEmpty
          ? _taxIdController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      city: _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : null,
      country: _countryController.text.trim().isNotEmpty
          ? _countryController.text.trim()
          : null,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      website: _websiteController.text.trim().isNotEmpty
          ? _websiteController.text.trim()
          : null,
      contactPersonName: _contactPersonNameController.text.trim().isNotEmpty
          ? _contactPersonNameController.text.trim()
          : null,
      contactPersonPhone: _contactPersonPhoneController.text.trim().isNotEmpty
          ? _contactPersonPhoneController.text.trim()
          : null,
      contactPersonEmail: _contactPersonEmailController.text.trim().isNotEmpty
          ? _contactPersonEmailController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final success = await context.read<BusinessProvider>().saveCompany(
      company,
    );
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      final saved = context.read<BusinessProvider>().selectedCompany;
      if (saved != null) {
        context.go('/business/company/${saved.id}');
      } else {
        context.pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Partenaire mis à jour avec succès'
                : 'Partenaire créé avec succès',
          ),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<BusinessProvider>().error ??
                'Erreur lors de l\'enregistrement',
          ),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}
