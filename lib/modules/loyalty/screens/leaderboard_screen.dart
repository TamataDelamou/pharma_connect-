import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/badge_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class LeaderboardScreen extends StatefulWidget {
  final String pharmacyId;

  const LeaderboardScreen({super.key, required this.pharmacyId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'all_time';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboard();
    });
  }

  void _onTabChanged() {
    final index = _tabController.index;
    setState(() {
      switch (index) {
        case 0:
          _selectedPeriod = 'daily';
          break;
        case 1:
          _selectedPeriod = 'weekly';
          break;
        case 2:
          _selectedPeriod = 'monthly';
          break;
      }
    });
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    context.read<BadgeProvider>().loadLeaderboard(
      pharmacyId: widget.pharmacyId,
      period: _selectedPeriod,
      limit: 20,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BadgeProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
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
                      '🏆 Classement',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 24),

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Aujourd\'hui'),
                Tab(text: 'Cette semaine'),
                Tab(text: 'Ce mois'),
              ],
              labelColor: context.palette.primary,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: context.palette.primary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.leaderboard.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun classement disponible',
                        style: context.text.body2,
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.leaderboard.length,
                      itemBuilder: (context, index) {
                        final entry = provider.leaderboard[index];
                        final isFirst = index == 0;
                        final isSecond = index == 1;
                        final isThird = index == 2;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isFirst
                                ? context.palette.warningStrong.withValues(
                                    alpha: 0.1,
                                  )
                                : isSecond
                                ? context.palette.textSecondary.withValues(
                                    alpha: 0.06,
                                  )
                                : isThird
                                ? context.palette.warning.withValues(
                                    alpha: 0.06,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFirst
                                  ? context.palette.warningStrong.withValues(
                                      alpha: 0.2,
                                    )
                                  : context.palette.surface,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  _getRankIcon(index),
                                  style: const TextStyle(fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: context.palette.primary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  (entry['patients']?['full_name']
                                          as String?)?[0] ??
                                      '?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.palette.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry['patients']?['full_name'] ?? 'Patient',
                                  style: TextStyle(
                                    fontWeight: isFirst
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${entry['points'] ?? 0} pts',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isFirst
                                      ? context.palette.warningStrong
                                      : context.palette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRankIcon(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '#${index + 1}';
    }
  }
}
