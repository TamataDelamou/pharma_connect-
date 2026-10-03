import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/solidarity_provider.dart';
import '../widgets/program_card.dart';

class SolidarityDashboardScreen extends StatefulWidget {
  final bool isStaff;

  const SolidarityDashboardScreen({super.key, this.isStaff = false});

  @override
  State<SolidarityDashboardScreen> createState() =>
      _SolidarityDashboardScreenState();
}

class _SolidarityDashboardScreenState extends State<SolidarityDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrograms();
    });
  }

  void _onTabChanged() {
    final index = _tabController.index;
    setState(() {
      switch (index) {
        case 0:
          _selectedType = null;
          break;
        case 1:
          _selectedType = 'free_medication';
          break;
        case 2:
          _selectedType = 'emergency_aid';
          break;
      }
    });
    _loadPrograms();
  }

  void _loadPrograms() {
    context.read<SolidarityProvider>().loadPrograms(
      type: _selectedType,
      isActive: true,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolidarityProvider>();
    // C232 : création de programme réservée à l'administration GSG (RLS
    // « Staff manage solidarity programs » : is_gsg_admin()). `isStaff` seul
    // ne dépend que de l'adresse (/solidarity/staff).
    final canManage =
        widget.isStaff && context.watch<AuthProvider>().isGsgAdmin;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accès solidaire',
                    style: PharmaConnectTypography.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Programmes d\'accès aux soins pour tous',
                    style: PharmaConnectTypography.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (canManage) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/solidarity/program/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau programme'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmaConnectColors.accentCyan,
                      foregroundColor: PharmaConnectColors.textOnAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Tous'),
                Tab(text: 'Médicaments gratuits'),
                Tab(text: 'Aide d\'urgence'),
              ],
              labelColor: PharmaConnectColors.accentCyan,
              unselectedLabelColor: PharmaConnectColors.textSecondary,
              indicatorColor: PharmaConnectColors.accentCyan,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 16),

            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SolidarityProvider provider) {
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
                _loadPrograms();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.programs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.handshake_outlined,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun programme solidaire',
              style: PharmaConnectTypography.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isStaff
                  ? 'Créez votre premier programme d\'accès solidaire'
                  : 'Aucun programme disponible pour le moment',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.programs.length,
      itemBuilder: (context, index) {
        final program = provider.programs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ProgramCard(
            program: program,
            onTap: () => context.push(
              '/solidarity/program/${program.id}',
              extra: widget.isStaff,
            ),
          ),
        );
      },
    );
  }
}
