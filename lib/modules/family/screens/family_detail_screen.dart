import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/family_link.dart';
import '../providers/family_provider.dart';
import '../models/family_link_status.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class FamilyDetailScreen extends StatefulWidget {
  final String linkId;

  const FamilyDetailScreen({super.key, required this.linkId});

  @override
  State<FamilyDetailScreen> createState() => _FamilyDetailScreenState();
}

class _FamilyDetailScreenState extends State<FamilyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().loadLink(widget.linkId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FamilyProvider>();
    final link = provider.selectedLink;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (link == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Lien introuvable',
            style: context.text.body2.copyWith(color: context.palette.danger),
          ),
        ),
      );
    }

    final isPatient = link.patientId == SupabaseService().currentUser?.id;
    final isFamilyMember =
        link.familyMemberId == SupabaseService().currentUser?.id;

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
                      'Détail du lien familial',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (link.status == FamilyLinkStatus.pending &&
                    isFamilyMember) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _acceptLink(context, link.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.success,
                      foregroundColor: context.palette.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      glow: link.status.isActive,
                      glowColor: link.status.isActive
                          ? context.palette.success
                          : context.palette.textSecondary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: link.status.isActive
                                      ? context.palette.success
                                      : context.palette.textSecondary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      link.patientName ?? link.patientId,
                                      style: context.text.heading3,
                                    ),
                                    Text(
                                      'Lien avec ${link.familyMemberName ?? link.familyMemberId}',
                                      style: context.text.body2,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    link.status,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  link.status.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _statusColor(link.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Relation', link.relationship),
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow(
                            'Invité le',
                            _formatDate(link.invitedAt),
                          ),
                          if (link.activatedAt != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Activé le',
                              _formatDate(link.activatedAt!),
                            ),
                          ],
                          if (link.revokedAt != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Révoqué le',
                              _formatDate(link.revokedAt!),
                            ),
                          ],
                          if (link.notes != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow('Notes', link.notes!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Permissions
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Permissions', style: context.text.heading3),
                          const SizedBox(height: 8),
                          _buildPermissionRow(
                            'Voir les dossiers de santé',
                            link.canViewRecords,
                          ),
                          _buildPermissionRow(
                            'Voir les ordonnances',
                            link.canViewPrescriptions,
                          ),
                          _buildPermissionRow(
                            'Prendre des rendez-vous',
                            link.canBookConsultations,
                          ),
                          _buildPermissionRow(
                            'Recevoir des alertes',
                            link.canReceiveAlerts,
                          ),
                          if (link.status == FamilyLinkStatus.active &&
                              isPatient) ...[
                            const SizedBox(height: 12),
                            SecondaryButton(
                              label: 'Modifier les permissions',
                              icon: Icons.settings,
                              onPressed: () =>
                                  _showPermissionsDialog(context, link),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    if (link.status == FamilyLinkStatus.active &&
                        (isPatient || isFamilyMember)) ...[
                      SecondaryButton(
                        label: isPatient
                            ? 'Révoquer le lien'
                            : 'Quitter ce lien',
                        icon: Icons.block,
                        onPressed: () => _confirmRevoke(context, link.id),
                      ),
                    ],

                    if (link.status == FamilyLinkStatus.pending &&
                        isPatient) ...[
                      SecondaryButton(
                        label: 'Annuler l\'invitation',
                        icon: Icons.close,
                        onPressed: () => _confirmDelete(context, link.id),
                      ),
                    ],

                    if (link.status == FamilyLinkStatus.revoked &&
                        (isPatient || isFamilyMember)) ...[
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, link.id),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.palette.danger,
                          side: BorderSide(color: context.palette.danger),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: context.text.label)),
          Expanded(child: Text(value, style: context.text.body1)),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.block,
            color: enabled
                ? context.palette.success
                : context.palette.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: context.text.body2)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(FamilyLinkStatus status) {
    switch (status) {
      case FamilyLinkStatus.pending:
        return context.palette.warning;
      case FamilyLinkStatus.active:
        return context.palette.success;
      case FamilyLinkStatus.revoked:
        return context.palette.danger;
    }
  }

  void _acceptLink(BuildContext context, String id) async {
    final success = await context.read<FamilyProvider>().updateLinkStatus(
      id,
      FamilyLinkStatus.active,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lien familial accepté !'),
          backgroundColor: context.palette.success,
        ),
      );
      context.read<FamilyProvider>().loadLink(id);
    }
  }

  void _showPermissionsDialog(BuildContext context, FamilyLink link) {
    bool canViewRecords = link.canViewRecords;
    bool canViewPrescriptions = link.canViewPrescriptions;
    bool canBookConsultations = link.canBookConsultations;
    bool canReceiveAlerts = link.canReceiveAlerts;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: context.palette.background,
          title: const Text('Modifier les permissions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: canViewRecords,
                onChanged: (v) => setState(() => canViewRecords = v ?? false),
                title: const Text('Voir les dossiers de santé'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: canViewPrescriptions,
                onChanged: (v) =>
                    setState(() => canViewPrescriptions = v ?? false),
                title: const Text('Voir les ordonnances'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: canBookConsultations,
                onChanged: (v) =>
                    setState(() => canBookConsultations = v ?? false),
                title: const Text('Prendre des rendez-vous'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: canReceiveAlerts,
                onChanged: (v) => setState(() => canReceiveAlerts = v ?? false),
                title: const Text('Recevoir des alertes'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = link.copyWith(
                  canViewRecords: canViewRecords,
                  canViewPrescriptions: canViewPrescriptions,
                  canBookConsultations: canBookConsultations,
                  canReceiveAlerts: canReceiveAlerts,
                );
                Navigator.pop(ctx);
                final success = await context.read<FamilyProvider>().updateLink(
                  updated,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Permissions mises à jour'),
                      backgroundColor: context.palette.success,
                    ),
                  );
                  context.read<FamilyProvider>().loadLink(link.id);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.primary,
                foregroundColor: context.palette.onPrimary,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRevoke(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Révoquer le lien'),
        content: const Text(
          'Êtes-vous sûr de vouloir révoquer ce lien familial ? Cette action est réversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<FamilyProvider>()
                  .updateLinkStatus(id, FamilyLinkStatus.revoked);
              if (success && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Lien révoqué')));
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.onDanger,
            ),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Supprimer'),
        content: const Text('Supprimer ce lien familial ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<FamilyProvider>().deleteLink(
                id,
              );
              if (success && context.mounted) {
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.onDanger,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
