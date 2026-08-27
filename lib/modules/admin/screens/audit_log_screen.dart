import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/audit_log.dart';
import '../providers/admin_provider.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String? _resourceFilter;

  static const _resources = ['user', 'pharmacy', 'config'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAuditLogs();
    });
  }

  void _selectResource(String? resource) {
    setState(() => _resourceFilter = resource);
    context.read<AdminProvider>().loadAuditLogs(resource: resource);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

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
                const Expanded(
                  child: Text(
                    "Journal d'audit",
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Historique centralisé des actions administratives (Kernel)',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'Tous',
                    selected: _resourceFilter == null,
                    onTap: () => _selectResource(null),
                  ),
                  for (final resource in _resources)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: _resourceLabel(resource),
                        selected: _resourceFilter == resource,
                        onTap: () => _selectResource(resource),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                            onPressed: () => _selectResource(_resourceFilter),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : provider.auditLogs.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucune entrée dans le journal d'audit",
                        style: PharmaConnectTypography.body2,
                      ),
                    )
                  : ListView.separated(
                      itemCount: provider.auditLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _AuditLogTile(log: provider.auditLogs[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _resourceLabel(String resource) {
    switch (resource) {
      case 'user':
        return 'Utilisateurs';
      case 'pharmacy':
        return 'Officines';
      case 'config':
        return 'Configuration';
      default:
        return resource;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? PharmaConnectColors.accentCyan.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? PharmaConnectColors.accentCyan
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? PharmaConnectColors.accentCyan
                  : PharmaConnectColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLog log;

  const _AuditLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final statusColor = log.isSuccess
        ? PharmaConnectColors.accentGreen
        : PharmaConnectColors.accentRed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            log.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.action} • ${log.resource} #${log.resourceId}',
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Par ${log.userName} — ${_formatTimestamp(log.timestamp)}',
                  style: PharmaConnectTypography.body2,
                ),
                if (log.errorMessage != null)
                  Text(
                    log.errorMessage!,
                    style: PharmaConnectTypography.micro.copyWith(
                      color: PharmaConnectColors.accentRed,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final d = timestamp;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
