import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/solidarity_program.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/solidarity_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class SolidarityProgramDetailScreen extends StatefulWidget {
  final String programId;
  final bool isStaff;

  const SolidarityProgramDetailScreen({
    super.key,
    required this.programId,
    this.isStaff = false,
  });

  @override
  State<SolidarityProgramDetailScreen> createState() =>
      _SolidarityProgramDetailScreenState();
}

class _SolidarityProgramDetailScreenState
    extends State<SolidarityProgramDetailScreen> {
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolidarityProvider>().loadProgram(widget.programId);
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _confirmDelete(SolidarityProgram program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce programme ?'),
        content: Text(
          'Cette action est définitive : « ${program.name} » sera supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Supprimer',
              style: TextStyle(color: context.palette.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final provider = context.read<SolidarityProvider>();
    final success = await provider.deleteProgram(program.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erreur lors de la suppression'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolidarityProvider>();
    final program = provider.selectedProgram;
    // C232 : suppression réservée à l'administration GSG (RLS « Staff manage
    // solidarity programs » : is_gsg_admin()), comme la création.
    final canManage =
        widget.isStaff && context.watch<AuthProvider>().isGsgAdmin;

    if (provider.isLoading && program == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (program == null || program.id != widget.programId) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Programme introuvable',
            style: context.text.body2.copyWith(color: context.palette.danger),
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
                    program.name,
                    style: context.text.heading2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (program.isActive
                                ? context.palette.success
                                : context.palette.danger)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    program.isActive ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: program.isActive
                          ? context.palette.success
                          : context.palette.danger,
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
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Type', program.typeLabel),
                          Divider(color: context.palette.veil(0.12)),
                          if (program.description != null) ...[
                            _buildInfoRow('Description', program.description!),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          if (program.pharmacyName != null) ...[
                            _buildInfoRow('Officine', program.pharmacyName!),
                            Divider(color: context.palette.veil(0.12)),
                          ],
                          _buildInfoRow(
                            'Début',
                            _formatDate(program.startDate),
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow(
                            'Fin',
                            program.endDate != null
                                ? _formatDate(program.endDate!)
                                : 'Non définie',
                          ),
                          if (program.budget != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Budget',
                              CurrencyFormatter.format(program.budget!),
                            ),
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Budget utilisé',
                              CurrencyFormatter.format(program.usedBudget),
                            ),
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Budget disponible',
                              CurrencyFormatter.format(program.availableBudget),
                            ),
                          ],
                          if (program.beneficiariesCount != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Bénéficiaires',
                              '${program.beneficiariesCount}',
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canManage) ...[
                      const SizedBox(height: 16),
                      TertiaryButton(
                        label: _isDeleting
                            ? 'Suppression...'
                            : 'Supprimer le programme',
                        isDisabled: _isDeleting,
                        icon: Icons.delete_outline,
                        onPressed: () => _confirmDelete(program),
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
          SizedBox(width: 120, child: Text(label, style: context.text.label)),
          Expanded(child: Text(value, style: context.text.body1)),
        ],
      ),
    );
  }
}
