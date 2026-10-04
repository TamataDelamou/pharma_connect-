import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/iot_provider.dart';
import '../models/iot_device.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IotProvider>().loadDevice(widget.deviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IotProvider>();
    final device = provider.selectedDevice;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (device == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Appareil introuvable',
            style: context.text.body2.copyWith(color: context.palette.danger),
          ),
        ),
      );
    }

    // Audit Module 21 (IOT), Étape 2 (30/08/2026), C99 : voir le correctif
    // et sa justification complète dans iot_dashboard_screen.dart.
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    final isOwner = device.pharmacyId == pharmacyId;

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
                      'Détail de l\'appareil',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(device.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    device.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(device.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Device info
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _deviceIcon(device.type),
                                style: const TextStyle(fontSize: 40),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.name,
                                      style: context.text.heading3,
                                    ),
                                    Text(
                                      device.typeLabel,
                                      style: context.text.body2,
                                    ),
                                    Text(
                                      device.deviceId,
                                      style: context.text.micro.copyWith(
                                        color:
                                            PharmaConnectColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Modèle',
                            device.model ?? 'Non spécifié',
                          ),
                          _buildInfoRow(
                            'Firmware',
                            device.firmwareVersion ?? 'Non spécifié',
                          ),
                          if (device.location != null)
                            _buildInfoRow('Localisation', device.location!),
                          if (device.lastReadingAt != null)
                            _buildInfoRow(
                              'Dernière lecture',
                              _formatDate(device.lastReadingAt!),
                            ),
                          if (device.lastBatteryLevel != null)
                            _buildInfoRow(
                              'Niveau batterie',
                              '${device.lastBatteryLevel}%',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Temperature readings
                    if (provider.readings.isNotEmpty) ...[
                      Text(
                        '🌡️ Dernières lectures',
                        style: context.text.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...provider.readings.take(5).map((reading) {
                        final isHigh = reading.temperature > 30;
                        final isLow = reading.temperature < 2;
                        final isNormal = !isHigh && !isLow;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isNormal
                                ? context.palette.surfaceMuted
                                : (isHigh
                                      ? context.palette.danger.withValues(
                                          alpha: 0.1,
                                        )
                                      : context.palette.primary.withValues(
                                          alpha: 0.1,
                                        )),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isNormal
                                  ? context.palette.surface
                                  : (isHigh
                                        ? context.palette.danger.withValues(
                                            alpha: 0.2,
                                          )
                                        : context.palette.primary.withValues(
                                            alpha: 0.2,
                                          )),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isHigh
                                    ? Icons.warning_amber
                                    : (isLow
                                          ? Icons.ac_unit
                                          : Icons.check_circle),
                                color: isNormal
                                    ? context.palette.success
                                    : (isHigh
                                          ? context.palette.danger
                                          : context.palette.primary),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${reading.temperature.toStringAsFixed(1)}${reading.unit}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isNormal
                                            ? context.palette.textPrimary
                                            : (isHigh
                                                  ? PharmaConnectColors
                                                        .accentRed
                                                  : PharmaConnectColors
                                                        .accentCyan),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(reading.timestamp),
                                      style: context.text.micro,
                                    ),
                                  ],
                                ),
                              ),
                              if (reading.isAlert)
                                Text(
                                  '⚠️ Alerte',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: context.palette.danger,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 16),

                    // Alerts
                    if (provider.alerts.isNotEmpty) ...[
                      Text('🚨 Alertes récentes', style: context.text.heading3),
                      const SizedBox(height: 8),
                      ...provider.alerts
                          .where((a) => a.status != 'resolved')
                          .take(3)
                          .map((alert) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: context.palette.danger.withValues(
                                  alpha: 0.06,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: context.palette.danger.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: context.palette.danger,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert.typeLabel,
                                          style: context.text.body1.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          alert.message,
                                          style: context.text.body2,
                                        ),
                                        Text(
                                          _formatDate(alert.createdAt),
                                          style: context.text.micro,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (alert.status == 'active' && isOwner)
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.thumb_up,
                                            size: 16,
                                          ),
                                          onPressed: () async {
                                            await provider.updateAlertStatus(
                                              alert.id,
                                              'acknowledged',
                                            );
                                            provider.loadDevice(
                                              widget.deviceId,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.done_all,
                                            size: 16,
                                          ),
                                          onPressed: () async {
                                            await provider.updateAlertStatus(
                                              alert.id,
                                              'resolved',
                                            );
                                            provider.loadDevice(
                                              widget.deviceId,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  if (alert.status == 'acknowledged')
                                    Text(
                                      'Accusée',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: context.palette.primary,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                    ],

                    const SizedBox(height: 24),

                    // Actions
                    if (isOwner) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Simuler une lecture',
                              icon: Icons.play_arrow,
                              onPressed: () async {
                                await provider.simulateReading(device.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lecture simulée ajoutée'),
                                      backgroundColor: context.palette.success,
                                    ),
                                  );
                                  provider.loadDevice(widget.deviceId);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Modifier',
                              icon: Icons.edit,
                              onPressed: () {
                                context.push('/iot/device/edit/${device.id}');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (device.status == 'active') ...[
                            Expanded(
                              child: SecondaryButton(
                                label: 'Mettre en maintenance',
                                icon: Icons.build,
                                onPressed: () => _updateStatus('maintenance'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SecondaryButton(
                                label: 'Désactiver',
                                icon: Icons.power_settings_new,
                                onPressed: () => _updateStatus('inactive'),
                              ),
                            ),
                          ] else if (device.status == 'inactive' ||
                              device.status == 'maintenance') ...[
                            Expanded(
                              child: PrimaryButton(
                                label: 'Réactiver',
                                icon: Icons.power_settings_new,
                                onPressed: () => _updateStatus('active'),
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _confirmDelete(context, device.id),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Supprimer'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.palette.danger,
                                side: BorderSide(color: context.palette.danger),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: context.text.label)),
          Expanded(child: Text(value, style: context.text.body1)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return context.palette.success;
      case 'inactive':
        return context.palette.textSecondary;
      case 'maintenance':
        return context.palette.warning;
      case 'offline':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
    }
  }

  String _deviceIcon(String type) {
    switch (type) {
      case 'temperature_sensor':
        return '🌡️';
      case 'humidity_sensor':
        return '💧';
      case 'cold_chain_monitor':
        return '❄️';
      case 'stock_scanner':
        return '📷';
      case 'motion_sensor':
        return '🔄';
      default:
        return '📡';
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final device = await context.read<IotProvider>().selectedDevice;
    if (device == null) return;

    final updated = device.copyWith(status: newStatus);
    final success = await context.read<IotProvider>().saveDevice(updated);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour : ${updated.statusLabel}'),
          backgroundColor: context.palette.success,
        ),
      );
      context.read<IotProvider>().loadDevice(widget.deviceId);
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Supprimer l\'appareil'),
        content: const Text(
          'Cette action supprimera définitivement l\'appareil et toutes ses données.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<IotProvider>().deleteDevice(
                id,
              );
              if (success && context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Appareil supprimé'),
                    backgroundColor: context.palette.danger,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.textPrimary,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
