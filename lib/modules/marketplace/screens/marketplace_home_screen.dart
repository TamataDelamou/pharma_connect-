import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import '../models/b2b_offer.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/offer_card.dart';
import '../widgets/order_card.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOffers();
    });
  }

  void _onTabChanged() {
    final index = _tabController.index;
    if (index == 0) {
      _loadOffers();
    } else if (index == 1) {
      _loadMyOffers();
    } else {
      _loadMyOrders();
    }
  }

  void _loadOffers() {
    context.read<MarketplaceProvider>().loadOffers(onlyActive: true);
  }

  // Audit Module 13 (B2B, 29/08/2026) : `_loadMyOffers`/`_loadMyOrders`
  // filtraient sur `SupabaseService().currentUser?.id` — l'identifiant de
  // l'UTILISATEUR, alors que `seller_pharmacy_id`/`buyer_pharmacy_id` sont
  // des identifiants d'OFFICINE. Même bug que les policies RLS corrigées
  // dans la même migration (20260829040000) : ces deux espaces d'identifiants
  // ne coïncident jamais, si bien que « Mes offres »/« Mes commandes »
  // n'affichaient jamais rien, quel que soit le compte connecté. Corrigé
  // via `AuthProvider.pharmacyId`, comme dans tous les autres modules
  // (StockProvider, PrescriptionProvider, etc.).
  void _loadMyOffers() {
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId != null) {
      context.read<MarketplaceProvider>().loadOffers(
        sellerPharmacyId: pharmacyId,
        onlyActive: false,
      );
    }
  }

  void _loadMyOrders() {
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId != null) {
      // `involvedPharmacyId` (et non buyer+seller séparément) : voir le
      // commentaire de MarketplaceService.getOrders — je suis acheteur OU
      // vendeur de ces commandes, jamais les deux à la fois.
      context.read<MarketplaceProvider>().loadOrders(
        involvedPharmacyId: pharmacyId,
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
    final provider = context.watch<MarketplaceProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🛒 Marketplace B2B',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Achetez et vendez entre professionnels',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/marketplace/offer/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Vendre'),
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

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '📦 Offres'),
                Tab(text: '📤 Mes offres'),
                Tab(text: '📋 Mes commandes'),
              ],
              labelColor: PharmaConnectColors.accentCyan,
              unselectedLabelColor: PharmaConnectColors.textSecondary,
              indicatorColor: PharmaConnectColors.accentCyan,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 16),

            // Audit Module 13 (B2B, 29/08/2026) : bandeau hors-ligne, même
            // patron que StockProvider/PrescriptionProvider (Modules 4/5).
            // Extension (clôture, 29/08/2026) : couvre désormais les trois
            // onglets — « Mes offres »/« Mes commandes » bénéficient aussi
            // d'un repli cache (cache_my_b2b_offers/cache_b2b_orders,
            // arbitrage porteur du projet) — le libellé s'adapte à l'onglet
            // actif.
            if (provider.isOffline) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: PharmaConnectColors.accentOrange.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: PharmaConnectColors.accentOrange.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: PharmaConnectColors.accentOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _tabController.index == 2
                            ? 'Hors connexion — dernières commandes synchronisées'
                            : _tabController.index == 1
                            ? 'Hors connexion — dernières offres (les vôtres) synchronisées'
                            : 'Hors connexion — dernières offres synchronisées',
                        style: PharmaConnectTypography.micro.copyWith(
                          color: PharmaConnectColors.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(MarketplaceProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Audit Module 13 (B2B, 29/08/2026) : `provider.isOffline` exclu ici —
    // sans cette garde, le message informatif du repli hors-ligne (stocké
    // dans le même champ `error` que les vraies erreurs, patron déjà établi
    // en Modules 2/4/5) ferait basculer tout l'écran en état d'erreur et
    // masquerait la liste d'offres mise en cache qu'on vient pourtant
    // d'afficher avec succès — même bug déjà évité au Module 5 (ORD).
    if (provider.error != null && !provider.isOffline) {
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
                _onTabChanged();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (_tabController.index == 2) {
      // Orders tab
      if (provider.orders.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.white24,
              ),
              SizedBox(height: 16),
              Text('Aucune commande', style: PharmaConnectTypography.heading3),
              SizedBox(height: 8),
              Text(
                'Vous n\'avez pas encore de commandes',
                style: PharmaConnectTypography.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        itemCount: provider.orders.length,
        itemBuilder: (context, index) {
          final order = provider.orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OrderCard(
              order: order,
              onTap: () => context.push('/marketplace/order/${order.id}'),
            ),
          );
        },
      );
    }

    // Offers tab (all or my offers)
    if (provider.offers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Aucune offre disponible',
              style: PharmaConnectTypography.heading3,
            ),
            SizedBox(height: 8),
            Text(
              'Soyez le premier à proposer un produit',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final isMyOffersTab = _tabController.index == 1;
    return ListView.builder(
      itemCount: provider.offers.length,
      itemBuilder: (context, index) {
        final offer = provider.offers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OfferCard(
            offer: offer,
            onTap: () => context.push('/marketplace/offer/${offer.id}'),
            onDelete: isMyOffersTab ? () => _confirmDeleteOffer(offer) : null,
          ),
        );
      },
    );
  }

  // Audit Module 13 (B2B, 29/08/2026, clôture) : réserve levée — bouton de
  // suppression avec confirmation dans « Mes offres ». Avertit explicitement
  // si l'offre est déjà référencée par des lignes de commande existantes
  // (b2b_order_items.offer_id est ON DELETE SET NULL : la suppression ne
  // supprime jamais ces lignes, mais les détache silencieusement de l'offre
  // d'origine si le vendeur n'est pas prévenu).
  Future<void> _confirmDeleteOffer(B2BOffer offer) async {
    final provider = context.read<MarketplaceProvider>();
    final linkedOrders = await provider.countLinkedOrdersForOffer(offer.id);
    final linkedNegotiations = await provider.countNegotiationsForOffer(
      offer.id,
    );
    if (!mounted) return;

    final warnings = <String>[];
    if (linkedOrders > 0) {
      warnings.add(
        '$linkedOrders ligne(s) de commande déjà passée(s) seront détachées '
        'de cette offre (les commandes elles-mêmes resteront intactes, mais '
        'ne seront plus retrouvables dans leur historique)',
      );
    }
    if (linkedNegotiations > 0) {
      warnings.add(
        '$linkedNegotiations négociation(s) liée(s) à cette offre seront '
        'définitivement supprimées',
      );
    }
    final message = warnings.isEmpty
        ? 'Supprimer définitivement l\'offre « ${offer.productName} » ?'
        : '${warnings.join('. ')}. Continuer ?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'offre'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: PharmaConnectColors.accentRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await provider.deleteOffer(offer.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Offre supprimée.'
              : (provider.error ?? 'Échec de la suppression — réessayez.'),
        ),
      ),
    );
  }
}
