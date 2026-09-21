import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../providers/professionals_provider.dart';
import '../widgets/professional_card.dart';

class ProfessionalsListScreen extends StatefulWidget {
  final bool isSelectMode;

  const ProfessionalsListScreen({super.key, this.isSelectMode = false});

  @override
  State<ProfessionalsListScreen> createState() =>
      _ProfessionalsListScreenState();
}

class _ProfessionalsListScreenState extends State<ProfessionalsListScreen> {
  final _searchController = TextEditingController();
  String? _selectedSpecialty;
  bool _showOnlyVerified = false;
  bool _showOnlyAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfessionals();
      context.read<ProfessionalsProvider>().loadSpecialties();
    });
  }

  void _loadProfessionals() {
    context.read<ProfessionalsProvider>().loadProfessionals(
      specialty: _selectedSpecialty,
      isVerified: _showOnlyVerified ? true : null,
      acceptingNewPatients: _showOnlyAvailable ? true : null,
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
    final provider = context.watch<ProfessionalsProvider>();

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
                        'Professionnels de santé',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Trouvez un professionnel pour vos soins',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 16),

            // Search
            GlassInput(
              label: '',
              hint: 'Rechercher un professionnel...',
              controller: _searchController,
              prefixIcon: Icons.search,
              suffixIcon: _searchController.text.isNotEmpty
                  ? Icons.clear
                  : null,
              onSuffixPressed: () {
                _searchController.clear();
                _loadProfessionals();
              },
              onChanged: (value) => _loadProfessionals(),
            ),
            const SizedBox(height: 12),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Specialty filter
                  if (provider.specialties.isNotEmpty) ...[
                    DropdownButton<String>(
                      value: _selectedSpecialty,
                      hint: const Text('Spécialité'),
                      dropdownColor: PharmaConnectColors.primaryDeep,
                      style: const TextStyle(
                        color: PharmaConnectColors.textPrimary,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Toutes'),
                        ),
                        ...provider.specialties.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.code,
                            child: Text(s.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSpecialty = value);
                        _loadProfessionals();
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Verified filter
                  FilterChip(
                    label: const Text('Vérifié'),
                    selected: _showOnlyVerified,
                    onSelected: (selected) {
                      setState(() => _showOnlyVerified = selected);
                      _loadProfessionals();
                    },
                    selectedColor: PharmaConnectColors.accentGreen.withValues(
                      alpha: 0.2,
                    ),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: _showOnlyVerified
                          ? PharmaConnectColors.accentGreen
                          : Colors.white24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Available filter
                  FilterChip(
                    label: const Text('Disponible'),
                    selected: _showOnlyAvailable,
                    onSelected: (selected) {
                      setState(() => _showOnlyAvailable = selected);
                      _loadProfessionals();
                    },
                    selectedColor: PharmaConnectColors.accentCyan.withValues(
                      alpha: 0.2,
                    ),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: _showOnlyAvailable
                          ? PharmaConnectColors.accentCyan
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

  Widget _buildContent(ProfessionalsProvider provider) {
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
                _loadProfessionals();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.professionals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 64,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun professionnel trouvé',
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
      itemCount: provider.professionals.length,
      itemBuilder: (context, index) {
        final professional = provider.professionals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ProfessionalCard(
            professional: professional,
            onTap: widget.isSelectMode
                ? () => Navigator.pop(context, professional)
                : () => context.push('/professionals/${professional.id}'),
            showSelectButton: widget.isSelectMode,
          ),
        );
      },
    );
  }
}
