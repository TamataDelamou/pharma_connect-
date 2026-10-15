import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/stock_status.dart';
import '../providers/stock_provider.dart';
import '../services/stock_summary_card.dart';
import '../widgets/stock_status_chip.dart';
import '../../../core/theme/palette.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pharmacyId = context.read<AuthProvider>().pharmacyId;
      context.read<StockProvider>().loadStock(pharmacyId: pharmacyId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final pharmacyId = context.watch<AuthProvider>().pharmacyId;

    // Audit Module 4 (29/08/2026) : un pharmacien dont la candidature n'est
    // pas encore vérifiée (RG-AUT-01, Module 1) n'a pas de pharmacyId — sans
    // ce garde-fou, l'écran appelait loadStock(pharmacyId: null) et
    // affichait le stock de TOUTES les officines mélangées.
    if (pharmacyId == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_pharmacy_outlined,
                  size: 64,
                  color: context.palette.veil(0.24),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune officine rattachée à votre compte',
                  style: context.text.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'La gestion du stock sera disponible dès que votre '
                  'candidature de licence aura été validée par le back-office.',
                  style: context.text.body2,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion des stocks',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Consultez et gérez les niveaux de stock',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                ElevatedButton.icon(
                  onPressed: () => context.push('/stock/movements'),
                  icon: const Icon(Icons.history),
                  label: const Text('Historique'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Audit Module 4 : StockSummaryCard existait déjà comme
            // composant mais n'était câblé dans aucun écran — un
            // pharmacien n'avait aucune vue d'ensemble de son inventaire
            // sans ouvrir l'écran Alertes séparément.
            if (provider.stockItems.isNotEmpty) ...[
              StockSummaryCard(
                totalProducts: provider.stockItems.length,
                totalStock: provider.stockItems.fold(
                  0,
                  (sum, item) => sum + item.availableQuantity,
                ),
                lowStockCount: provider.criticalStockItems.length,
                outOfStockCount: provider.outOfStockItems.length,
              ),
              const SizedBox(height: 16),
            ],

            if (provider.isOffline) ...[
              _buildOfflineBanner(provider),
              const SizedBox(height: 12),
            ],

            // Barre de recherche
            GlassInput(
              label: '',
              hint: 'Rechercher un produit...',
              controller: _searchController,
              prefixIcon: Icons.search,
              suffixIcon: _searchController.text.isNotEmpty
                  ? Icons.clear
                  : null,
              onSuffixPressed: () {
                _searchController.clear();
                provider.search('', pharmacyId: pharmacyId);
              },
              onChanged: (value) {
                setState(() {});
                provider.search(value, pharmacyId: pharmacyId);
              },
            ),
            const SizedBox(height: 16),

            // Contenu
            Expanded(child: _buildContent(provider, pharmacyId)),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner(StockProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.warningStrong.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.palette.warningStrong.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: context.palette.warningStrong),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.error ??
                  'Hors-ligne — données affichées depuis le cache local.',
              style: context.text.micro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StockProvider provider, String pharmacyId) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.stockItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.error!,
              style: context.text.body2.copyWith(color: context.palette.danger),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadStock(pharmacyId: pharmacyId),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (provider.stockItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucun stock disponible', style: context.text.heading2),
            SizedBox(height: 8),
            Text('Les produits apparaîtront ici', style: context.text.body2),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.stockItems.length,
      itemBuilder: (context, index) {
        final item = provider.stockItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            onTap: () => context.push('/stock/${item.id}'),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.palette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: item.status.color.of(context.palette),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2, // C265 : nom ou adresse, 2 lignes au plus.
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.product.genericName,
                        style: context.text.body2,
                        maxLines: 2, // C265 : nom ou adresse, 2 lignes au plus.
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // C265 : passe à la ligne au lieu de déborder à
                      // 360 px, à côté de la pastille d'état.
                      Wrap(
                        spacing: 12,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Stock : ${item.availableQuantity}',
                            style: context.text.body2.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Réservés : ${item.reservedQuantity}',
                            style: context.text.micro,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Statut
                StockStatusChip(status: item.status, showLabel: true),
              ],
            ),
          ),
        );
      },
    );
  }
}
