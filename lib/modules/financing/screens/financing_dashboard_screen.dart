import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/financing_provider.dart';
import '../widgets/financing_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class FinancingDashboardScreen extends StatefulWidget {
  const FinancingDashboardScreen({super.key});

  @override
  State<FinancingDashboardScreen> createState() =>
      _FinancingDashboardScreenState();
}

class _FinancingDashboardScreenState extends State<FinancingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Bug corrigé (audit Module 14, 29/08/2026) : utilisait l'identifiant
      // UTILISATEUR (`SupabaseService().currentUser?.id`) là où
      // `pharmacyId` (identifiant OFFICINE) est attendu, même confusion
      // que C43 — le tableau de bord ne chargeait donc jamais les bonnes
      // données (RLS aujourd'hui stricte sur `pharmacy_id`, avant cela un
      // filtre silencieusement inopérant).
      final pharmacyId = context.read<AuthProvider>().pharmacyId;
      if (pharmacyId != null) {
        context.read<FinancingProvider>().loadRequests(pharmacyId: pharmacyId);
        context.read<FinancingProvider>().loadCreditScore(pharmacyId);
      }
    });
  }

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
          _selectedStatus = 'active';
          break;
      }
    });
    _loadRequests();
  }

  void _loadRequests() {
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId != null) {
      context.read<FinancingProvider>().loadRequests(
        pharmacyId: pharmacyId,
        status: _selectedStatus,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinancingProvider>();
    final credit = provider.creditScore;

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
                    '💰 Financement',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Financement pour grossistes et pharmacies',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                ElevatedButton.icon(
                  onPressed: () => context.push('/financing/request/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Demander'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Credit Score
            if (credit != null)
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _scoreColor(
                          credit.score,
                        ).withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          credit.score.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _scoreColor(credit.score),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Score de crédit', style: context.text.body2),
                          Text(
                            credit.ratingLabel,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _scoreColor(credit.score),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Dernière mise à jour: ${_formatDate(credit.lastUpdated)}',
                                style: context.text.micro,
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  final pharmacyId = context
                                      .read<AuthProvider>()
                                      .pharmacyId;
                                  if (pharmacyId != null) {
                                    context
                                        .read<FinancingProvider>()
                                        .refreshCreditScore(pharmacyId);
                                  }
                                },
                                child: const Text('Rafraîchir'),
                                style: TextButton.styleFrom(
                                  foregroundColor: context.palette.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Toutes'),
                Tab(text: 'En attente'),
                Tab(text: 'Actives'),
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

  Widget _buildContent(FinancingProvider provider) {
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
                _loadRequests();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucune demande de financement', style: context.text.heading3),
            SizedBox(height: 8),
            Text(
              'Demandez un financement pour votre activité',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.requests.length,
      itemBuilder: (context, index) {
        final request = provider.requests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FinancingCard(
            request: request,
            onTap: () => context.push('/financing/${request.id}'),
          ),
        );
      },
    );
  }

  Color _scoreColor(int score) {
    if (score >= 800) return context.palette.success;
    if (score >= 700) return context.palette.primary;
    if (score >= 600) return context.palette.warningStrong;
    if (score >= 500) return context.palette.warning;
    return context.palette.danger;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
