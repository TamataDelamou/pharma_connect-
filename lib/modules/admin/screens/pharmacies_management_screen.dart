import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../models/admin_pharmacy.dart';
import '../models/pharmacy_status.dart';
import '../providers/admin_provider.dart';
import '../../../core/theme/palette.dart';

class PharmaciesManagementScreen extends StatefulWidget {
  const PharmaciesManagementScreen({super.key});

  @override
  State<PharmaciesManagementScreen> createState() =>
      _PharmaciesManagementScreenState();
}

class _PharmaciesManagementScreenState
    extends State<PharmaciesManagementScreen> {
  PharmacyStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queryStatus = GoRouterState.of(
        context,
      ).uri.queryParameters['status'];
      PharmacyStatus? initial;
      for (final status in PharmacyStatus.values) {
        if (status.name == queryStatus) {
          initial = status;
          break;
        }
      }
      setState(() => _statusFilter = initial);
      context.read<AdminProvider>().loadPharmacies(status: initial);
    });
  }

  void _selectFilter(PharmacyStatus? status) {
    setState(() => _statusFilter = status);
    context.read<AdminProvider>().loadPharmacies(status: status);
  }

  Future<void> _updateStatus(
    AdminPharmacy pharmacy,
    PharmacyStatus status,
    String successMessage,
  ) async {
    final palette = context.palette;
    final provider = context.read<AdminProvider>();
    final ok = await provider.updatePharmacyStatus(pharmacy.id, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? successMessage : (provider.error ?? 'Échec de la mise à jour'),
          ),
          backgroundColor: ok ? palette.success : palette.danger,
        ),
      );
    }
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
                      'Gestion des officines',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 8),
            Text(
              'Validation DNPM, statut et licences des officines',
              style: context.text.body2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'Toutes',
                    selected: _statusFilter == null,
                    onTap: () => _selectFilter(null),
                  ),
                  for (final status in PharmacyStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: status.label,
                        selected: _statusFilter == status,
                        onTap: () => _selectFilter(status),
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
                            style: context.text.body2.copyWith(
                              color: context.palette.danger,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _selectFilter(_statusFilter),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : provider.pharmacies.isEmpty
                  ? Center(
                      child: Text('Aucune officine', style: context.text.body2),
                    )
                  : ListView.builder(
                      itemCount: provider.pharmacies.length,
                      itemBuilder: (context, index) {
                        final pharmacy = provider.pharmacies[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PharmacyCard(
                            pharmacy: pharmacy,
                            onVerify: () => _updateStatus(
                              pharmacy,
                              PharmacyStatus.verified,
                              'Officine vérifiée',
                            ),
                            onApprove: () => _updateStatus(
                              pharmacy,
                              PharmacyStatus.active,
                              'Officine activée',
                            ),
                            onSuspend: () => _updateStatus(
                              pharmacy,
                              PharmacyStatus.suspended,
                              'Officine suspendue',
                            ),
                            onReactivate: () => _updateStatus(
                              pharmacy,
                              PharmacyStatus.active,
                              'Officine réactivée',
                            ),
                            onReject: () => _updateStatus(
                              pharmacy,
                              PharmacyStatus.rejected,
                              'Officine rejetée',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
              ? context.palette.primary.withValues(alpha: 0.15)
              : context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? context.palette.primary
                : context.palette.surfaceRaised,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? context.palette.primary
                  : context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final AdminPharmacy pharmacy;
  final VoidCallback onVerify;
  final VoidCallback onApprove;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;
  final VoidCallback onReject;

  const _PharmacyCard({
    required this.pharmacy,
    required this.onVerify,
    required this.onApprove,
    required this.onSuspend,
    required this.onReactivate,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pharmacy.name,
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pharmacy.statusColor
                      .of(context.palette)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pharmacy.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: pharmacy.statusColor.of(context.palette),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(pharmacy.address, style: context.text.body2),
          Text(
            '${pharmacy.phone} • ${pharmacy.licenseNumber ?? 'Sans licence déclarée'}',
            style: context.text.mono,
          ),
          if (pharmacy.managerName != null)
            Text('Gérant : ${pharmacy.managerName}', style: context.text.micro),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (pharmacy.status == PharmacyStatus.pending) ...[
                OutlinedButton(
                  onPressed: onVerify,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.palette.primary),
                    foregroundColor: context.palette.primary,
                  ),
                  child: const Text('Vérifier la licence'),
                ),
              ],
              if (pharmacy.status == PharmacyStatus.verified ||
                  pharmacy.status == PharmacyStatus.underReview) ...[
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.success,
                    foregroundColor: context.palette.onPrimary,
                  ),
                  child: const Text('Approuver'),
                ),
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.palette.danger),
                    foregroundColor: context.palette.danger,
                  ),
                  child: const Text('Rejeter'),
                ),
              ],
              if (pharmacy.status == PharmacyStatus.active) ...[
                OutlinedButton(
                  onPressed: onSuspend,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.palette.warning),
                    foregroundColor: context.palette.warning,
                  ),
                  child: const Text('Suspendre'),
                ),
              ],
              if (pharmacy.status == PharmacyStatus.suspended) ...[
                ElevatedButton(
                  onPressed: onReactivate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.success,
                    foregroundColor: context.palette.onPrimary,
                  ),
                  child: const Text('Réactiver'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
