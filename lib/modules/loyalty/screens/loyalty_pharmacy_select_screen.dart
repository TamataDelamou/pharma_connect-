import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../providers/loyalty_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

/// Audit Module 16 (FID, 29/08/2026) : `loyalty_accounts` n'a qu'une
/// contrainte d'unicité par (patient_id, pharmacy_id) — un patient peut
/// avoir un compte fidélité dans plusieurs officines, et rien avant ce
/// module ne permettait de choisir laquelle (l'écran de tableau de bord
/// retombait silencieusement sur la chaîne littérale 'default_pharmacy',
/// qui n'est ni un UUID ni une officine réelle — toute requête réelle
/// échouait). Cet écran couvre le strict minimum demandé par le porteur du
/// projet (question 2, « sélecteur d'officine minimal ») : lister les
/// comptes déjà rejoints, et permettre d'en rejoindre un nouveau parmi les
/// officines actives — pas une recherche géographique/multi-critères
/// complète comme `search_service.dart` (Module 2), hors périmètre ici.
class LoyaltyPharmacySelectScreen extends StatefulWidget {
  const LoyaltyPharmacySelectScreen({super.key});

  @override
  State<LoyaltyPharmacySelectScreen> createState() =>
      _LoyaltyPharmacySelectScreenState();
}

class _LoyaltyPharmacySelectScreenState
    extends State<LoyaltyPharmacySelectScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      if (userId != null) {
        context.read<LoyaltyProvider>().loadMyAccounts(userId);
      }
      context.read<LoyaltyProvider>().loadActivePharmacies();
    });
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoyaltyProvider>();
    final filteredPharmacies = _query.isEmpty
        ? provider.pharmacies
        : provider.pharmacies
              .where(
                (p) =>
                    (p['name'] as String? ?? '').toLowerCase().contains(_query),
              )
              .toList();
    final joinedPharmacyIds = provider.myAccounts
        .map((a) => a.pharmacyId)
        .toSet();

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
                    'Programme de fidélité',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text('Choisissez une officine', style: context.text.body2),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 24),
            Expanded(
              child:
                  provider.isLoading &&
                      provider.myAccounts.isEmpty &&
                      provider.pharmacies.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (provider.myAccounts.isNotEmpty) ...[
                            Text(
                              'Mes programmes',
                              style: context.text.heading3,
                            ),
                            const SizedBox(height: 8),
                            ...provider.myAccounts.map((account) {
                              return GestureDetector(
                                onTap: () => context.push(
                                  '/loyalty/${account.pharmacyId}',
                                ),
                                // Phase 4 (module loyalty) : GlassCard
                                // (widget partagé) n'expose pas de paramètre
                                // `margin` - même défaut de compilation que
                                // professional_reviews_screen.dart (Phase 3).
                                // Corrigé pareillement : Padding inséré
                                // entre GestureDetector et GlassCard.
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GlassCard(
                                    child: Row(
                                      children: [
                                        Text(
                                          account.tierEmoji,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                account.pharmacyName ??
                                                    'Officine',
                                                style: context.text.body1
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              Text(
                                                '${account.pointsBalance} points • ${account.tierLabel}',
                                                style: context.text.body2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: context.palette.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                          ],
                          Text(
                            'Rejoindre une officine',
                            style: context.text.heading3,
                          ),
                          const SizedBox(height: 8),
                          GlassInput(
                            label: 'Rechercher une officine',
                            hint: 'Nom de l\'officine',
                            controller: _searchController,
                            prefixIcon: Icons.search,
                          ),
                          const SizedBox(height: 8),
                          if (filteredPharmacies.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Aucune officine trouvée',
                                style: context.text.body2,
                              ),
                            )
                          else
                            ...filteredPharmacies
                                .where(
                                  (p) => !joinedPharmacyIds.contains(
                                    p['id'] as String,
                                  ),
                                )
                                .map((pharmacy) {
                                  return GestureDetector(
                                    onTap: () => context.push(
                                      '/loyalty/${pharmacy['id']}',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: context.palette.surface,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pharmacy['name'] as String? ??
                                                      'Officine',
                                                  style: context.text.body1,
                                                ),
                                                if (pharmacy['address'] != null)
                                                  Text(
                                                    pharmacy['address']
                                                        as String,
                                                    style: context.text.micro,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color:
                                                context.palette.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
