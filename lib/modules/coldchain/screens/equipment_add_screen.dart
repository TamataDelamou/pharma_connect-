import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../models/equipment_type.dart';
import '../providers/coldchain_provider.dart';

class EquipmentAddScreen extends StatefulWidget {
  const EquipmentAddScreen({super.key});

  @override
  State<EquipmentAddScreen> createState() => _EquipmentAddScreenState();
}

class _EquipmentAddScreenState extends State<EquipmentAddScreen> {
  final _nameController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _modelController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _locationController = TextEditingController();
  EquipmentType _selectedType = EquipmentType.refrigerator;

  @override
  void dispose() {
    _nameController.dispose();
    _serialNumberController.dispose();
    _modelController.dispose();
    _manufacturerController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ColdChainProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
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
                    'Ajouter un équipement',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GlassCard(
                      child: Column(
                        children: [
                          Text(
                            'Type d\'équipement',
                            style: PharmaConnectTypography.label,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<EquipmentType>(
                            value: _selectedType,
                            dropdownColor: PharmaConnectColors.primaryDeep,
                            style: PharmaConnectTypography.body1,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: PharmaConnectColors.accentCyan,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: EquipmentType.values.map((type) {
                              return DropdownMenuItem<EquipmentType>(
                                value: type,
                                child: Text('${type.icon} ${type.label}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          GlassInput(
                            label: 'Nom de l\'équipement',
                            hint: 'Ex. Réfrigérateur Pharmacie Centrale',
                            controller: _nameController,
                            prefixIcon: Icons.label_outline,
                          ),
                          const SizedBox(height: 16),
                          GlassInput(
                            label: 'Numéro de série',
                            hint: 'SN-000000',
                            controller: _serialNumberController,
                            prefixIcon: Icons.confirmation_number_outlined,
                          ),
                          const SizedBox(height: 16),
                          GlassInput(
                            label: 'Modèle',
                            hint: 'Ex. MediCool 200',
                            controller: _modelController,
                            prefixIcon: Icons.inventory_2_outlined,
                          ),
                          const SizedBox(height: 16),
                          GlassInput(
                            label: 'Fabricant',
                            hint: 'Ex. Liebherr',
                            controller: _manufacturerController,
                            prefixIcon: Icons.factory_outlined,
                          ),
                          const SizedBox(height: 16),
                          GlassInput(
                            label: 'Emplacement (optionnel)',
                            hint: 'Ex. Salle de stockage',
                            controller: _locationController,
                            prefixIcon: Icons.place_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Ajouter l\'équipement',
                      isLoading: provider.isLoading,
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        final serialNumber = _serialNumberController.text
                            .trim();
                        final model = _modelController.text.trim();
                        final manufacturer = _manufacturerController.text
                            .trim();

                        if (name.isEmpty ||
                            serialNumber.isEmpty ||
                            model.isEmpty ||
                            manufacturer.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez remplir tous les champs requis'),
                              backgroundColor: PharmaConnectColors.accentRed,
                            ),
                          );
                          return;
                        }

                        final created = await provider.createEquipment(
                          name: name,
                          type: _selectedType,
                          serialNumber: serialNumber,
                          model: model,
                          manufacturer: manufacturer,
                          minTemperature: _selectedType.defaultMinTemperature,
                          maxTemperature: _selectedType.defaultMaxTemperature,
                          location: _locationController.text.trim().isEmpty
                              ? null
                              : _locationController.text.trim(),
                        );

                        if (!context.mounted) return;

                        if (created != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Équipement ajouté avec succès'),
                              backgroundColor: PharmaConnectColors.accentGreen,
                            ),
                          );
                          context.pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur lors de l\'ajout de l\'équipement'),
                              backgroundColor: PharmaConnectColors.accentRed,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
