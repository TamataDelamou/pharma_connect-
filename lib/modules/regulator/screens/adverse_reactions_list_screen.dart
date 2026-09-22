import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/regulator_provider.dart';
import '../widgets/adverse_reaction_anonymized_card.dart';
import '../widgets/adverse_reaction_card.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-3 (2e occurrence) :
// l'ancien paramètre de construction `isRegulator` (jamais lié à un rôle
// réel) et la route dédiée `/regulator/staff` sont supprimés (cf.
// app_router.dart). Cet écran s'auto-adapte désormais au rôle réel de
// l'utilisateur connecté (AuthProvider), en 3 modes :
//  - rôle métier 'regulateur'  -> vue agrégée anonymisée uniquement
//    (RG-REG-02 / REG-5), aucune navigation vers un détail nominatif ;
//  - staff GSG (isGsgAdmin)    -> gestion de cas sur la table brute
//    (comportement historique de l'ancien /regulator/staff) ;
//  - tout autre compte         -> ses propres signalements + bouton
//    "Signaler" (comportement historique inchangé).
// Ces booléens ne pilotent que l'affichage : RLS (Étape 2) reste le seul
// rempart réel côté serveur dans les 3 cas.
class AdverseReactionsListScreen extends StatefulWidget {
  const AdverseReactionsListScreen({super.key});

  @override
  State<AdverseReactionsListScreen> createState() =>
      _AdverseReactionsListScreenState();
}

class _AdverseReactionsListScreenState extends State<AdverseReactionsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReactions();
    });
  }

  bool get _isRegulateur =>
      context.read<AuthProvider>().userRole == UserRole.regulateur;

  void _onTabChanged() {
    final index = _tabController.index;
    setState(() {
      switch (index) {
        case 0:
          _selectedStatus = null;
          break;
        case 1:
          _selectedStatus = 'pending';
          break;
        case 2:
          _selectedStatus = 'investigating';
          break;
      }
    });
    _loadReactions();
  }

  void _loadReactions() {
    if (_isRegulateur) {
      context.read<RegulatorProvider>().loadReactionsAnonymized(
        status: _selectedStatus,
      );
    } else {
      context.read<RegulatorProvider>().loadReactions(status: _selectedStatus);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegulatorProvider>();
    final auth = context.watch<AuthProvider>();
    final isRegulateur = auth.userRole == UserRole.regulateur;
    final canManage = auth.isGsgAdmin;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pharmacovigilance',
                        style: PharmaConnectTypography.heading1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRegulateur
                            ? 'Statistiques agrégées et anonymisées des signalements'
                            : 'Signalez et suivez les effets indésirables',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                if (!isRegulateur) ...[
                  ElevatedButton.icon(
                    onPressed: () => context.push('/regulator/report'),
                    icon: const Icon(Icons.add),
                    label: const Text('Signaler'),
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
            const SizedBox(height: 16),

            // Accès rapide staff GSG / régulateur aux autres volets du
            // module (REG-4 : inspections et AMM, désormais raccordées).
            if (canManage || isRegulateur) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.push('/regulator/inspections'),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Inspections'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PharmaConnectColors.accentPurple,
                        side: const BorderSide(
                          color: PharmaConnectColors.accentPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/regulator/authorizations'),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('AMM'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PharmaConnectColors.accentPurple,
                        side: const BorderSide(
                          color: PharmaConnectColors.accentPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Toutes'),
                Tab(text: 'En attente'),
                Tab(text: 'En investigation'),
              ],
              labelColor: PharmaConnectColors.accentCyan,
              unselectedLabelColor: PharmaConnectColors.textSecondary,
              indicatorColor: PharmaConnectColors.accentCyan,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: isRegulateur
                  ? _buildAnonymizedContent(provider)
                  : _buildContent(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RegulatorProvider provider) {
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
                _loadReactions();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.reactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Aucun signalement', style: PharmaConnectTypography.heading3),
            SizedBox(height: 8),
            Text(
              'Aucun effet indésirable n\'a été signalé',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.reactions.length,
      itemBuilder: (context, index) {
        final reaction = provider.reactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AdverseReactionCard(
            reaction: reaction,
            onTap: () => context.push('/regulator/${reaction.id}'),
          ),
        );
      },
    );
  }

  Widget _buildAnonymizedContent(RegulatorProvider provider) {
    if (provider.isLoadingAnonymized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.anonymizedError != null) {
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
              provider.anonymizedError!,
              textAlign: TextAlign.center,
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: _loadReactions,
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.anonymizedReactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Aucun signalement', style: PharmaConnectTypography.heading3),
            SizedBox(height: 8),
            Text(
              'Aucun effet indésirable n\'a été signalé sur cette période',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.anonymizedReactions.length,
      itemBuilder: (context, index) {
        final reaction = provider.anonymizedReactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AdverseReactionAnonymizedCard(reaction: reaction),
        );
      },
    );
  }
}
