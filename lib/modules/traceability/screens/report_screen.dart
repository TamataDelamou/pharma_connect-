import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/traceability_provider.dart';

/// Audit Module 12 (TRC), arbitrage D20 (29/08/2026) : écran manquant au
/// cahier — RG-TRC-02 (« signalement d'un produit suspect ») n'avait ni
/// écran ni méthode de service avant ce correctif (voir
/// TraceabilityService.reportSuspiciousProduct). Ouvert à TOUT utilisateur
/// authentifié (patient compris) — contrairement à ReceptionScreen, qui est
/// réservé à la chaîne d'approvisionnement — car un patient est la première
/// ligne de détection d'un produit suspect (aspect, emballage, effet
/// inattendu).
class ReportScreen extends StatefulWidget {
  final String? batchId;
  final String? serialNumber;

  const ReportScreen({super.key, this.batchId, this.serialNumber});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _serialController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _aspectSuspect = false;
  bool _packagingSuspect = false;
  bool _unexpectedEffect = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.serialNumber != null) {
      _serialController.text = widget.serialNumber!;
    }
  }

  @override
  void dispose() {
    _serialController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TraceabilityProvider>();

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
                    'Signaler un produit suspect',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Décrivez ce qui vous semble anormal. L\'officine concernée '
              'et l\'administrateur GSG sont alertés immédiatement '
              '(RG-TRC-02).',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: _submitted
                    ? _buildSuccess()
                    : _buildForm(context, provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, TraceabilityProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassInput(
          label: 'Numéro de série ou de lot (si connu)',
          hint: 'Ex: SN-DOL-001-2024',
          controller: _serialController,
          prefixIcon: Icons.qr_code,
        ),
        const SizedBox(height: 12),
        GlassInput(
          label: 'Description',
          hint: 'Que constatez-vous ? Depuis quand ?',
          controller: _descriptionController,
          prefixIcon: Icons.edit_note,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ce qui vous semble suspect',
          style: PharmaConnectTypography.label,
        ),
        CheckboxListTile(
          value: _aspectSuspect,
          onChanged: (v) => setState(() => _aspectSuspect = v ?? false),
          title: const Text(
            'Aspect du produit (couleur, texture, odeur…)',
            style: PharmaConnectTypography.body2,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: _packagingSuspect,
          onChanged: (v) => setState(() => _packagingSuspect = v ?? false),
          title: const Text(
            'Emballage (sceau, étiquette, orthographe…)',
            style: PharmaConnectTypography.body2,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: _unexpectedEffect,
          onChanged: (v) => setState(() => _unexpectedEffect = v ?? false),
          title: const Text(
            'Effet inattendu après la prise',
            style: PharmaConnectTypography.body2,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Envoyer le signalement',
          isLoading: provider.isSubmittingReport,
          onPressed: () => _submit(context, provider),
        ),
        if (provider.error != null) ...[
          const SizedBox(height: 12),
          Text(
            provider.error!,
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Icon(
          Icons.check_circle,
          color: PharmaConnectColors.accentGreen,
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          'Signalement envoyé',
          style: PharmaConnectTypography.heading3,
        ),
        const SizedBox(height: 8),
        const Text(
          'L\'officine concernée (si identifiée) et l\'administrateur GSG '
          'ont été alertés. Merci pour votre vigilance.',
          style: PharmaConnectTypography.body2,
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Retour',
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  Future<void> _submit(
    BuildContext context,
    TraceabilityProvider provider,
  ) async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez décrire ce qui vous semble suspect'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await provider.reportSuspiciousProduct(
      batchId: widget.batchId,
      serialNumber: _serialController.text.trim().isEmpty
          ? null
          : _serialController.text.trim(),
      pharmacyId: authProvider.pharmacyId,
      description: _descriptionController.text.trim(),
      aspectSuspect: _aspectSuspect,
      packagingSuspect: _packagingSuspect,
      unexpectedEffect: _unexpectedEffect,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _submitted = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Échec de l\'envoi du signalement'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}
