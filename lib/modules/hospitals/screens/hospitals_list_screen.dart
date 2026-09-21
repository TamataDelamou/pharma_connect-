import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../providers/hospitals_provider.dart';
import '../widgets/hospital_card.dart';

class HospitalsListScreen extends StatefulWidget {
  final bool isSelectMode;

  const HospitalsListScreen({super.key, this.isSelectMode = false});

  @override
  State<HospitalsListScreen> createState() => _HospitalsListScreenState();
}

class _HospitalsListScreenState extends State<HospitalsListScreen> {
  final _searchController = TextEditingController();
  String? _selectedTypeId;
  String? _selectedCity;
  bool _showOnlyEmergency = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHospitals();
      context.read<HospitalsProvider>().loadHospitalTypes();
    });
  }

  void _loadHospitals() {
    context.read<HospitalsProvider>().loadHospitals(
      typeId: _selectedTypeId,
      city: _selectedCity,
      isActive: true,
      hasEmergency: _showOnlyEmergency ? true : null,
      searchQuery: _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HospitalsProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.isSelectMode) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: PharmaConnectColors.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                ],
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Établissements de santé',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Trouvez un hôpital ou une clinique près de chez vous',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 16),

            GlassInput(
              label: '',
              hint: 'Rechercher un établissement...',
              controller: _searchController,
              prefixIcon: Icons.search,
              suffixIcon: _searchController.text.isNotEmpty
                  ? Icons.clear
                  : null,
              onSuffixPressed: () {
                _searchController.clear();
                _loadHospitals();
              },
              onChanged: (value) => _loadHospitals(),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Type filter
                  if (provider.hospitalTypes.isNotEmpty) ...[
                    DropdownButton<String>(
                      value: _selectedTypeId,
                      hint: const Text('Type'),
                      dropdownColor: PharmaConnectColors.primaryDeep,
                      style: const TextStyle(
                        color: PharmaConnectColors.textPrimary,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tous'),
                        ),
                        ...provider.hospitalTypes.map((t) {
                          return DropdownMenuItem<String>(
                            value: t.id,
                            child: Text(t.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedTypeId = value);
                        _loadHospitals();
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                  // City filter
                  DropdownButton<String>(
                    value: _selectedCity,
                    hint: const Text('Ville'),
                    dropdownColor: PharmaConnectColors.primaryDeep,
                    style: const TextStyle(
                      color: PharmaConnectColors.textPrimary,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Toutes'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'Conakry',
                        child: Text('Conakry'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'Kindia',
                        child: Text('Kindia'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'N\'Zérékoré',
                        child: Text('N\'Zérékoré'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCity = value);
                      _loadHospitals();
                    },
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('Urgences'),
                    selected: _showOnlyEmergency,
                    onSelected: (selected) {
                      setState(() => _showOnlyEmergency = selected);
                      _loadHospitals();
                    },
                    selectedColor: PharmaConnectColors.accentRed.withValues(
                      alpha: 0.2,
                    ),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: _showOnlyEmergency
                          ? PharmaConnectColors.accentRed
                          : Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(HospitalsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: PharmaConnectColors.accentRed,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                _loadHospitals();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.hospitals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 64,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun établissement trouvé',
              style: PharmaConnectTypography.heading3,
            ),
            SizedBox(height: 8),
            Text(
              'Ajustez vos filtres ou recherchez autre chose',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.hospitals.length,
      itemBuilder: (context, index) {
        final hospital = provider.hospitals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HospitalCard(
            hospital: hospital,
            onTap: widget.isSelectMode
                ? () => Navigator.pop(context, hospital)
                : () => context.push('/hospitals/${hospital.id}'),
            showSelectButton: widget.isSelectMode,
          ),
        );
      },
    );
  }
}
