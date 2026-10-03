import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../providers/alert_provider.dart';
import '../models/alert_type.dart';
import '../models/alert_severity.dart';
import '../models/alert_preferences.dart';

class AlertPreferencesScreen extends StatefulWidget {
  const AlertPreferencesScreen({super.key});

  @override
  State<AlertPreferencesScreen> createState() => _AlertPreferencesScreenState();
}

class _AlertPreferencesScreenState extends State<AlertPreferencesScreen> {
  late AlertPreferences _preferences;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AlertProvider>();
      provider.loadPreferences().then((_) {
        setState(() {
          _preferences = provider.preferences;
        });
      });
    });
    _preferences = const AlertPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();

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
                      'Préférences de notifications',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 8),
            const Text(
              'Gérez comment vous recevez les alertes',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Canaux
                    _buildSectionTitle('Canaux de notification'),
                    _buildSwitchTile(
                      label: 'Notifications push',
                      value: _preferences.pushEnabled,
                      onChanged: (value) {
                        setState(() {
                          _preferences = _preferences.copyWith(
                            pushEnabled: value,
                          );
                        });
                      },
                    ),
                    _buildSwitchTile(
                      label: 'Notifications par email',
                      value: _preferences.emailEnabled,
                      onChanged: (value) {
                        setState(() {
                          _preferences = _preferences.copyWith(
                            emailEnabled: value,
                          );
                        });
                      },
                    ),
                    _buildSwitchTile(
                      label: 'Notifications in-app',
                      value: _preferences.inAppEnabled,
                      onChanged: (value) {
                        setState(() {
                          _preferences = _preferences.copyWith(
                            inAppEnabled: value,
                          );
                        });
                      },
                    ),
                    _buildSwitchTile(
                      label: 'Son des notifications',
                      value: _preferences.soundEnabled,
                      onChanged: (value) {
                        setState(() {
                          _preferences = _preferences.copyWith(
                            soundEnabled: value,
                          );
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Par niveau de priorité'),
                    for (final severity in AlertSeverity.values) ...[
                      _buildSwitchTile(
                        label: severity.label,
                        value: _preferences.severityEnabled[severity] ?? true,
                        onChanged: (value) {
                          setState(() {
                            _preferences = _preferences.copyWith(
                              severityEnabled: {
                                ..._preferences.severityEnabled,
                                severity: value,
                              },
                            );
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 24),
                    _buildSectionTitle('Par type d\'alerte'),
                    for (final type in AlertType.values) ...[
                      _buildSwitchTile(
                        label: type.label,
                        value: _preferences.typeEnabled[type] ?? true,
                        onChanged: (value) {
                          setState(() {
                            _preferences = _preferences.copyWith(
                              typeEnabled: {
                                ..._preferences.typeEnabled,
                                type: value,
                              },
                            );
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Enregistrer les préférences',
                      isLoading: provider.isLoading,
                      onPressed: () async {
                        await provider.updatePreferences(_preferences);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Préférences enregistrées'),
                              backgroundColor: PharmaConnectColors.accentGreen,
                            ),
                          );
                          context.pop();
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: PharmaConnectTypography.heading3),
    );
  }

  Widget _buildSwitchTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(label, style: PharmaConnectTypography.body1),
      value: value,
      onChanged: onChanged,
      activeColor: PharmaConnectColors.accentCyan,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
