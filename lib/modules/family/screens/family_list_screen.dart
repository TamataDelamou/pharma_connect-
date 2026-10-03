import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../providers/family_provider.dart';
import '../models/family_link_status.dart';
import '../widgets/family_link_card.dart';
import '../widgets/family_alert_badge.dart';

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      if (userId != null) {
        context.read<FamilyProvider>().loadLinks(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FamilyProvider>();

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
                    'Famille & Diaspora',
                    style: PharmaConnectTypography.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gérez vos liens familiaux pour le suivi santé',
                    style: PharmaConnectTypography.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                FamilyAlertBadge(
                  count: provider.unreadAlertCount,
                  onTap: () => context.push('/family/alerts'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => context.push('/family/new'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Incoming requests banner
            if (provider.incomingRequests.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: PharmaConnectColors.accentOrange.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: PharmaConnectColors.accentOrange.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications,
                      color: PharmaConnectColors.accentOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${provider.incomingRequests.length} demande(s) en attente',
                        style: PharmaConnectTypography.body1,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/family/requests'),
                      child: const Text('Voir'),
                    ),
                  ],
                ),
              ),
            ],

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Mes liens'),
                Tab(text: 'Alertes'),
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

  Widget _buildContent(FamilyProvider provider) {
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
                final userId = SupabaseService().currentUser?.id;
                if (userId != null) provider.loadLinks(userId);
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (_tabController.index == 0) {
      // Links tab
      if (provider.links.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_outlined, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text(
                'Aucun lien familial',
                style: PharmaConnectTypography.heading3,
              ),
              SizedBox(height: 8),
              Text(
                'Ajoutez un membre de votre famille pour partager vos informations de santé',
                style: PharmaConnectTypography.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: provider.links.length,
        itemBuilder: (context, index) {
          final link = provider.links[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FamilyLinkCard(
              link: link,
              onTap: () => context.push('/family/${link.id}'),
            ),
          );
        },
      );
    } else {
      // Alerts tab
      if (provider.alerts.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 64,
                color: Colors.white24,
              ),
              SizedBox(height: 16),
              Text('Aucune alerte', style: PharmaConnectTypography.heading3),
              SizedBox(height: 8),
              Text(
                'Les alertes de santé de votre famille apparaîtront ici',
                style: PharmaConnectTypography.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: provider.alerts.length,
        itemBuilder: (context, index) {
          final alert = provider.alerts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () async {
                if (!alert.isRead) {
                  await provider.markAlertRead(alert.id);
                }
                // C232 : pas d'écran de détail d'une alerte ; la liste des
                // alertes (/family/alerts) la montre.
                context.push('/family/alerts');
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alert.isRead
                      ? Colors.transparent
                      : PharmaConnectColors.accentCyan.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: alert.isRead
                        ? Colors.white.withValues(alpha: 0.06)
                        : PharmaConnectColors.accentCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: alert.isRead
                            ? PharmaConnectColors.textSecondary
                            : PharmaConnectColors.accentCyan,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: alert.isRead
                                ? PharmaConnectTypography.body1.copyWith(
                                    color: PharmaConnectColors.textSecondary,
                                  )
                                : PharmaConnectTypography.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          ),
                          Text(
                            alert.message,
                            style: PharmaConnectTypography.body2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(alert.createdAt),
                            style: PharmaConnectTypography.micro,
                          ),
                        ],
                      ),
                    ),
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: PharmaConnectColors.accentCyan,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }
}
