import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/traceable_batch.dart';
import '../providers/traceability_provider.dart';
import '../../../core/theme/palette.dart';

/// Audit Module 12 (TRC), arbitrage D19 (29/08/2026) : écran manquant au
/// cahier — RG-TRC-01 exige une chaîne de traçabilité continue (fabricant →
/// grossiste → officine → patient), mais aucun écran ni méthode ne
/// permettait d'enregistrer la réception d'un lot avant ce correctif (voir
/// TraceabilityService.receiveBatch). Réservé aux maillons de la chaîne
/// d'approvisionnement (pharmacien, grossiste, régulateur) — jamais au
/// patient — même scope que la policy RLS `traceable_batches_write_staff`.
const List<String> _locationTypes = [
  'manufacturer',
  'distributor',
  'pharmacy',
  'patient',
];

String _locationTypeLabel(String value) {
  switch (value) {
    case 'manufacturer':
      return 'Fabricant';
    case 'distributor':
      return 'Grossiste';
    case 'pharmacy':
      return 'Officine';
    case 'patient':
      return 'Patient';
    default:
      return value;
  }
}

class ReceptionScreen extends StatefulWidget {
  const ReceptionScreen({super.key});

  @override
  State<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends State<ReceptionScreen> {
  final _searchController = TextEditingController();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();
  final _trackingController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _notesController = TextEditingController();

  TraceableBatch? _selectedBatch;
  String _fromLocationType = 'distributor';
  String _toLocationType = 'pharmacy';
  bool _isColdChainRequired = false;

  @override
  void initState() {
    super.initState();
    // Écoute directe du TextEditingController plutôt qu'un éventuel
    // paramètre onChanged de GlassInput (widget non modifié par cet audit,
    // API non garantie ici) — technique Flutter standard qui fonctionne
    // quelle que soit l'implémentation interne du widget.
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TraceabilityProvider>();
      if (provider.batches.isEmpty) {
        provider.loadBatches();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _trackingController.dispose();
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().effectiveRole;
    final isAuthorized =
        role == UserRole.pharmacien ||
        role == UserRole.grossiste ||
        role == UserRole.regulateur;

    if (!isAuthorized) {
      return _buildUnauthorized(context);
    }

    final provider = context.watch<TraceabilityProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Text(
              'Enregistrez la réception d\'un lot pour maintenir la chaîne '
              'de traçabilité continue (RG-TRC-01).',
              style: context.text.body2,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedBatch == null) ...[
                      GlassInput(
                        label: 'Rechercher un lot',
                        hint: 'Numéro de lot, numéro de série ou produit',
                        controller: _searchController,
                        prefixIcon: Icons.search,
                      ),
                      const SizedBox(height: 12),
                      _buildSearchResults(provider),
                    ] else ...[
                      _buildSelectedBatchCard(),
                      const SizedBox(height: 16),
                      _buildReceptionForm(provider),
                    ],
                    if (provider.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        provider.error!,
                        style: context.text.body2.copyWith(
                          color: context.palette.danger,
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: () => context.pop(),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Réceptionner un lot', style: context.text.heading2),
        ),
        const KernelBadge(),
      ],
    );
  }

  Widget _buildUnauthorized(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: Center(
                child: Text(
                  'Cet écran est réservé aux pharmaciens, grossistes et '
                  'régulateurs.',
                  style: context.text.body2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(TraceabilityProvider provider) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return Text(
        'Saisissez au moins un caractère pour rechercher un lot déjà connu '
        'du système.',
        style: context.text.micro,
      );
    }
    final results = provider.batches.where((b) {
      return b.batchNumber.toLowerCase().contains(query) ||
          b.serialNumber.toLowerCase().contains(query) ||
          b.productName.toLowerCase().contains(query);
    }).toList();

    if (results.isEmpty) {
      return Text('Aucun lot correspondant.', style: context.text.body2);
    }

    return Column(
      children: results.take(10).map((batch) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            onTap: () => _selectBatch(batch),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.productName,
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Lot: ${batch.batchNumber} • ${batch.statusLabel}',
                        style: context.text.micro,
                      ),
                    ],
                  ),
                ),
                if (batch.isRecalled || batch.isCounterfeit)
                  Icon(Icons.warning, color: context.palette.danger, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _selectBatch(TraceableBatch batch) {
    setState(() {
      _selectedBatch = batch;
      _toLocationType = 'pharmacy';
      _fromLocationType = batch.status.name == 'manufactured'
          ? 'manufacturer'
          : 'distributor';
      _fromLocationController.text = batch.distributor.isNotEmpty
          ? batch.distributor
          : batch.manufacturer;
      _toLocationController.text = '';
    });
  }

  Widget _buildSelectedBatchCard() {
    final batch = _selectedBatch!;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.productName, style: context.text.heading3),
                Text(
                  'Lot: ${batch.batchNumber} • SN: ${batch.serialNumber}',
                  style: context.text.body2,
                ),
                Text(
                  'Statut actuel : ${batch.statusLabel}',
                  style: context.text.micro,
                ),
                if (batch.isRecalled || batch.isCounterfeit) ...[
                  const SizedBox(height: 4),
                  Text(
                    batch.isRecalled
                        ? '⚠️ Lot rappelé — réception bloquée'
                        : '⚠️ Lot signalé contrefait — réception bloquée',
                    style: context.text.body2.copyWith(
                      color: context.palette.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedBatch = null),
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceptionForm(TraceabilityProvider provider) {
    final blocked = _selectedBatch!.isRecalled || _selectedBatch!.isCounterfeit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLocationTypeDropdown(
                label: 'Provenance',
                value: _fromLocationType,
                onChanged: (v) => setState(() => _fromLocationType = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLocationTypeDropdown(
                label: 'Destination',
                value: _toLocationType,
                onChanged: (v) => setState(() => _toLocationType = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassInput(
          label: 'Lieu de provenance',
          hint: 'Ex: Grossiste Nord SARL',
          controller: _fromLocationController,
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 12),
        GlassInput(
          label: 'Lieu de destination',
          hint: 'Ex: Pharmacie Centrale',
          controller: _toLocationController,
          prefixIcon: Icons.flag_outlined,
        ),
        const SizedBox(height: 12),
        GlassInput(
          label: 'Numéro de suivi (optionnel)',
          hint: 'Ex: TRK-2026-000123',
          controller: _trackingController,
          prefixIcon: Icons.local_shipping_outlined,
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _isColdChainRequired,
          onChanged: (v) => setState(() => _isColdChainRequired = v ?? false),
          title: Text(
            'Ce lot nécessite la chaîne du froid',
            style: context.text.body2,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        if (_isColdChainRequired) ...[
          GlassInput(
            label: 'Température relevée (°C)',
            hint: 'Ex: 4',
            controller: _temperatureController,
            prefixIcon: Icons.thermostat_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
        ],
        GlassInput(
          label: 'Notes (optionnel)',
          hint: 'Observations sur cette réception',
          controller: _notesController,
          prefixIcon: Icons.notes_outlined,
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Confirmer la réception',
          isLoading: provider.isReceiving,
          onPressed: blocked ? null : () => _submit(provider),
        ),
      ],
    );
  }

  Widget _buildLocationTypeDropdown({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.label),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.palette.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.palette.veil(0.24)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: context.palette.background,
              style: context.text.body2,
              items: _locationTypes
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(_locationTypeLabel(t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(TraceabilityProvider provider) async {
    final batch = _selectedBatch!;
    if (_fromLocationController.text.trim().isEmpty ||
        _toLocationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez renseigner la provenance et la destination'),
          backgroundColor: context.palette.danger,
        ),
      );
      return;
    }

    final temperature = _temperatureController.text.trim().isEmpty
        ? null
        : int.tryParse(_temperatureController.text.trim());

    final success = await provider.receiveBatch(
      batchId: batch.id,
      fromLocation: _fromLocationController.text.trim(),
      toLocation: _toLocationController.text.trim(),
      fromLocationType: _fromLocationType,
      toLocationType: _toLocationType,
      trackingNumber: _trackingController.text.trim().isEmpty
          ? null
          : _trackingController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      temperature: temperature,
      isColdChainRequired: _isColdChainRequired,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réception enregistrée'),
          backgroundColor: context.palette.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Échec de la réception'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }
}
