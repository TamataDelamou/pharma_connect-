import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/solidarity_provider.dart';
import '../widgets/program_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

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
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accès solidaire',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Programmes d\'accès aux soins pour tous',
                    style: context.text.body2,
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
                      backgroundColor: context.palette.primary,
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

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Tous'),
                Tab(text: 'Médicaments gratuits'),
                Tab(text: 'Aide d\'urgence'),
              ],
              labelColor: context.palette.primary,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: context.palette.primary,
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
            Icon(Icons.error_outline, size: 48, color: context.palette.danger),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: context.text.body2.copyWith(color: context.palette.danger),
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
            Icon(
              Icons.handshake_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            const SizedBox(height: 16),
            Text('Aucun programme solidaire', style: context.text.heading3),
            const SizedBox(height: 8),
            Text(
              widget.isStaff
                  ? 'Créez votre premier programme d\'accès solidaire'
                  : 'Aucun programme disponible pour le moment',
              style: context.text.body2,
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
