import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/cold_equipment.dart';
import '../models/equipment_type.dart';
import '../models/temperature_record.dart';
import '../providers/coldchain_provider.dart';
import '../widgets/temperature_record_tile.dart';
import '../widgets/incident_tile.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final String equipmentId;

  const EquipmentDetailScreen({super.key, required this.equipmentId});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ColdChainProvider>().loadEquipment(widget.equipmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ColdChainProvider>();
    final equipment = provider.selectedEquipment;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (equipment == null) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // C233 : en-tête adaptable (actions sous le titre sur téléphone).
              HeaderRow(
                leading: Row(
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
                    const Expanded(
                      child: Text(
                        'Détail de l\'équipement',
                        style: PharmaConnectTypography.heading2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: [const KernelBadge()],
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: Center(
                  child: Text(
                    'Équipement introuvable',
                    style: PharmaConnectTypography.body2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                    'Détail de l\'équipement',
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
                    // Informations générales
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                equipment.type.icon,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      equipment.name,
                                      style: PharmaConnectTypography.heading3,
                                    ),
                                    Text(
                                      '${equipment.type.label} • ${equipment.model}',
                                      style: PharmaConnectTypography.body2,
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(equipment),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Température actuelle',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      '${equipment.currentTemperature.toStringAsFixed(1)}°C',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: equipment.isTemperatureValid
                                            ? PharmaConnectColors.accentGreen
                                            : PharmaConnectColors.accentRed,
                                      ),
                                    ),
                                    Text(
                                      equipment.temperatureStatus,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: equipment.isTemperatureValid
                                            ? PharmaConnectColors.accentGreen
                                            : PharmaConnectColors.accentRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Plage de température',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      '${equipment.minTemperature}°C - ${equipment.maxTemperature}°C',
                                      style: PharmaConnectTypography.body1,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SN',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      equipment.serialNumber,
                                      style: PharmaConnectTypography.body1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (equipment.location != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '📍 ${equipment.location}',
                              style: PharmaConnectTypography.body2,
                            ),
                          ],
                          if (equipment.notes != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '📝 ${equipment.notes}',
                              style: PharmaConnectTypography.micro,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Graphique des températures
                    if (provider.temperatureRecords.isNotEmpty) ...[
                      const Text(
                        'Historique des températures',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      GlassCard(
                        child: SizedBox(
                          height: 150,
                          child: _buildTemperatureChart(
                            provider.temperatureRecords,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Bouton ajout température manuelle
                    PrimaryButton(
                      label: 'Ajouter un relevé manuel',
                      icon: Icons.add,
                      onPressed: () => _showAddTemperatureDialog(context),
                    ),
                    const SizedBox(height: 16),

                    // Derniers relevés
                    if (provider.temperatureRecords.isNotEmpty) ...[
                      const Text(
                        'Derniers relevés',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...provider.temperatureRecords
                          .take(5)
                          .map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: TemperatureRecordTile(record: record),
                            ),
                          ),
                      const SizedBox(height: 16),
                    ],

                    // Incidents
                    if (provider.incidents.isNotEmpty) ...[
                      const Text(
                        'Incidents de température',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...provider.incidents.map(
                        (incident) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: IncidentTile(
                            incident: incident,
                            onResolve: () async {
                              await provider.resolveIncident(
                                incident.id,
                                resolutionNotes: 'Résolu par le pharmacien',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Incident résolu'),
                                    backgroundColor:
                                        PharmaConnectColors.accentGreen,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ColdEquipment equipment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: equipment.statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: equipment.statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        equipment.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: equipment.statusColor,
        ),
      ),
    );
  }

  Widget _buildTemperatureChart(List<TemperatureRecord> records) {
    final limitedRecords = records.take(24).toList().reversed.toList();
    if (limitedRecords.isEmpty)
      return const Center(child: Text('Aucune donnée'));

    final minTemp = limitedRecords.fold(
      100.0,
      (min, r) => r.temperature < min ? r.temperature : min,
    );
    final maxTemp = limitedRecords.fold(
      -100.0,
      (max, r) => r.temperature > max ? r.temperature : max,
    );
    final range = maxTemp - minTemp;
    final padding = range * 0.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: limitedRecords.asMap().entries.map((entry) {
              final index = entry.key.toDouble();
              final value = limitedRecords[entry.key].temperature;
              final normalizedY =
                  (value - minTemp + padding) / (range + 2 * padding);
              return FlSpot(index, normalizedY);
            }).toList(),
            isCurved: true,
            color: _getChartColor(limitedRecords),
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minX: 0,
        maxX: limitedRecords.length.toDouble() - 1,
        minY: 0,
        maxY: 1,
      ),
    );
  }

  Color _getChartColor(List<TemperatureRecord> records) {
    final hasAlert = records.any((r) => r.isAlert);
    return hasAlert
        ? PharmaConnectColors.accentRed
        : PharmaConnectColors.accentCyan;
  }

  void _showAddTemperatureDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Ajouter un relevé manuel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Température (°C)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final temp = double.tryParse(controller.text);
              if (temp == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Température invalide'),
                    backgroundColor: PharmaConnectColors.accentRed,
                  ),
                );
                return;
              }

              final success = await context
                  .read<ColdChainProvider>()
                  .addManualTemperature(
                    equipmentId: widget.equipmentId,
                    temperature: temp,
                    recordedBy: 'Pharmacien',
                  );

              Navigator.pop(context);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Relevé enregistré'),
                    backgroundColor: PharmaConnectColors.accentGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
