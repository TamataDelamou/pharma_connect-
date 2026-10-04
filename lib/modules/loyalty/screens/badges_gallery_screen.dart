import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/badge_provider.dart';
import '../models/loyalty_badge.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class BadgesGalleryScreen extends StatefulWidget {
  const BadgesGalleryScreen({super.key});

  @override
  State<BadgesGalleryScreen> createState() => _BadgesGalleryScreenState();
}

class _BadgesGalleryScreenState extends State<BadgesGalleryScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      if (userId != null) {
        context.read<BadgeProvider>().loadBadges();
        context.read<BadgeProvider>().loadPatientBadges(userId);
      }
    });
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
                      '🏅 Galerie de badges',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.earnedBadges.length} badges débloqués sur ${provider.allBadges.length}',
              style: context.text.body2,
            ),
            const SizedBox(height: 16),

            // Category filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('all', 'Tous'),
                  _buildCategoryChip('health', 'Santé'),
                  _buildCategoryChip('activity', 'Activité'),
                  _buildCategoryChip('social', 'Social'),
                  _buildCategoryChip('special', 'Spécial'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.palette.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style: context.text.body2.copyWith(
                              color: context.palette.danger,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: () {
                              provider.clearError();
                              final userId = SupabaseService().currentUser?.id;
                              if (userId != null) {
                                provider.loadBadges();
                                provider.loadPatientBadges(userId);
                              }
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filteredBadges(provider).length,
                      itemBuilder: (context, index) {
                        final badge = _filteredBadges(provider)[index];
                        final isEarned = provider.hasBadge(badge.id);
                        return GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Audit Module 16 (FID, 29/08/2026), correctif
                              // de compilation (bug 3/3 de ce module) :
                              // `TextStyle` n'a pas de paramètre `opacity`
                              // (`The named parameter 'opacity' isn't
                              // defined`) — remplacé par un widget `Opacity`
                              // englobant, seul moyen correct d'atténuer un
                              // `Text` en Flutter.
                              Opacity(
                                opacity: isEarned ? 1.0 : 0.3,
                                child: Text(
                                  isEarned ? badge.icon : '🔒',
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                badge.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isEarned
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isEarned
                                      ? context.palette.textPrimary
                                      : context.palette.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (isEarned)
                                Text(
                                  '✅ Débloqué',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.palette.success,
                                  ),
                                )
                              else if (badge.requirementType != null &&
                                  badge.requirementValue != null)
                                Text(
                                  '${badge.requirementValue} ${badge.requirementLabel}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: context.palette.textSecondary,
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

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedCategory = value);
          }
        },
        selectedColor: context.palette.primary.withValues(alpha: 0.2),
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: isSelected
              ? context.palette.primary
              : context.palette.veil(0.24),
        ),
      ),
    );
  }

  List<LoyaltyBadge> _filteredBadges(BadgeProvider provider) {
    if (_selectedCategory == 'all') return provider.allBadges;
    return provider.allBadges
        .where((b) => b.category == _selectedCategory)
        .toList();
  }
}
