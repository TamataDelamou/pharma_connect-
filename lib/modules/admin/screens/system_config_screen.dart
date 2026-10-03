import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/system_config.dart';
import '../providers/admin_provider.dart';

class SystemConfigScreen extends StatefulWidget {
  const SystemConfigScreen({super.key});

  @override
  State<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends State<SystemConfigScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadConfigs();
    });
  }

  Future<void> _editConfig(SystemConfig config) async {
    final controller = TextEditingController(text: config.value);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: Text(config.key),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config.description != null) ...[
              Text(config.description!, style: PharmaConnectTypography.body2),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Valeur'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (newValue == null || newValue == config.value || !mounted) return;

    final provider = context.read<AdminProvider>();
    final ok = await provider.updateConfig(config.key, newValue, 'admin');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Paramètre ${config.key} mis à jour'
                : (provider.error ?? 'Échec de la mise à jour'),
          ),
          backgroundColor: ok
              ? PharmaConnectColors.accentGreen
              : PharmaConnectColors.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final byCategory = <String, List<SystemConfig>>{};
    for (final config in provider.configs) {
      byCategory.putIfAbsent(config.category, () => []).add(config);
    }

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
                      'Configuration système',
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
              'Paliers, seuils et intégrations du système',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Erreur : ${provider.error}',
                            style: PharmaConnectTypography.body2.copyWith(
                              color: PharmaConnectColors.accentRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<AdminProvider>().loadConfigs(),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : byCategory.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun paramètre configuré',
                        style: PharmaConnectTypography.body2,
                      ),
                    )
                  : ListView(
                      children: byCategory.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _categoryLabel(entry.key),
                                style: PharmaConnectTypography.heading3,
                              ),
                              const SizedBox(height: 8),
                              ...entry.value.map(
                                (config) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _ConfigTile(
                                    config: config,
                                    onTap: config.isEditable
                                        ? () => _editConfig(config)
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'general':
        return 'Général';
      case 'security':
        return 'Sécurité';
      default:
        return category;
    }
  }
}

class _ConfigTile extends StatelessWidget {
  final SystemConfig config;
  final VoidCallback? onTap;

  const _ConfigTile({required this.config, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.key,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (config.description != null)
                  Text(
                    config.description!,
                    style: PharmaConnectTypography.body2,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: PharmaConnectColors.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              config.value,
              style: const TextStyle(
                color: PharmaConnectColors.accentCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: PharmaConnectColors.textSecondary,
              ),
              onPressed: onTap,
            ),
          ],
        ],
      ),
    );
  }
}
