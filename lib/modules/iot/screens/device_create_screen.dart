import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/iot_provider.dart';
import '../models/iot_device.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class DeviceCreateScreen extends StatefulWidget {
  final String? deviceId;

  const DeviceCreateScreen({super.key, this.deviceId});

  @override
  State<DeviceCreateScreen> createState() => _DeviceCreateScreenState();
}

class _DeviceCreateScreenState extends State<DeviceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _modelController = TextEditingController();
  final _firmwareController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedType = 'temperature_sensor';
  bool _isLoading = false;

  final List<Map<String, String>> _deviceTypes = const [
    {'value': 'temperature_sensor', 'label': 'Capteur de température'},
    {'value': 'humidity_sensor', 'label': 'Capteur d\'humidité'},
    {'value': 'cold_chain_monitor', 'label': 'Moniteur chaîne du froid'},
    {'value': 'stock_scanner', 'label': 'Scanner de stock'},
    {'value': 'motion_sensor', 'label': 'Capteur de mouvement'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _deviceIdController.dispose();
    _modelController.dispose();
    _firmwareController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.deviceId == null
                          ? '📡 Ajouter un appareil'
                          : '📡 Modifier l\'appareil',
                      style: context.text.heading2,
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
                              label: 'Nom de l\'appareil',
                              hint: 'Ex: Capteur frigo 1',
                              controller: _nameController,
                              prefixIcon: Icons.devices,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un nom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'ID de l\'appareil',
                              hint: 'Ex: SENSOR-001',
                              controller: _deviceIdController,
                              prefixIcon: Icons.qr_code,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un ID unique';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Device type
                            DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Type d\'appareil',
                                border: OutlineInputBorder(),
                              ),
                              items: _deviceTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type['value'],
                                  child: Text(type['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null)
                                  setState(() => _selectedType = value);
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Modèle (optionnel)',
                              hint: 'Ex: DHT22',
                              controller: _modelController,
                              prefixIcon: Icons.memory,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Version firmware (optionnel)',
                              hint: 'Ex: v1.2.3',
                              controller: _firmwareController,
                              prefixIcon: Icons.code,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Localisation (optionnel)',
                              hint: 'Ex: Réfrigérateur - Zone B',
                              controller: _locationController,
                              prefixIcon: Icons.location_on,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.palette.primary.withValues(
                            alpha: 0.06,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.palette.primary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: context.palette.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Une fois connecté, l\'appareil enverra automatiquement ses données.',
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
                        label: _isLoading
                            ? widget.deviceId == null
                                  ? 'Ajout...'
                                  : 'Mise à jour...'
                            : widget.deviceId == null
                            ? 'Ajouter l\'appareil'
                            : 'Mettre à jour',
                        isLoading: _isLoading,
                        onPressed: _saveDevice,
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

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;

    // Audit Module 21 (IOT), Étape 2 (30/08/2026), C99 : voir le correctif
    // et sa justification complète dans iot_dashboard_screen.dart —
    // `pharmacyId` doit être l'id de la ligne `pharmacies`, pas l'id du
    // compte utilisateur connecté.
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune officine rattachée à ce compte')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final device = IotDevice(
      id: widget.deviceId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      pharmacyId: pharmacyId,
      deviceId: _deviceIdController.text.trim(),
      name: _nameController.text.trim(),
      type: _selectedType,
      model: _modelController.text.trim().isNotEmpty
          ? _modelController.text.trim()
          : null,
      firmwareVersion: _firmwareController.text.trim().isNotEmpty
          ? _firmwareController.text.trim()
          : null,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      status: 'active',
      config: {},
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context.read<IotProvider>().saveDevice(device);
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.deviceId == null
                ? 'Appareil ajouté avec succès'
                : 'Appareil mis à jour',
          ),
          backgroundColor: context.palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<IotProvider>().error ?? 'Erreur'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }
}
