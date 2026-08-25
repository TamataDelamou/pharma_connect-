import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../models/stock_status.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_status_chip.dart';

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
      context.read<StockProvider>().loadStock();
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion des stocks',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Consultez et gérez les niveaux de stock',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/stock/movements'),
                  icon: const Icon(Icons.history),
                  label: const Text('Historique'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentPurple,
                    foregroundColor: PharmaConnectColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                provider.search('');
              },
              onChanged: (value) {
                setState(() {});
                provider.search(value);
              },
            ),
            const SizedBox(height: 16),

            // Contenu
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(StockProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erreur : ${provider.error}',
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadStock(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (provider.stockItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Aucun stock disponible',
              style: PharmaConnectTypography.heading2,
            ),
            SizedBox(height: 8),
            Text(
              'Les produits apparaîtront ici',
              style: PharmaConnectTypography.body2,
            ),
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
                    color: PharmaConnectColors.accentCyan.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: item.status.color,
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
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.product.genericName,
                        style: PharmaConnectTypography.body2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Stock : ${item.availableQuantity}',
                            style: PharmaConnectTypography.body2.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Réservés : ${item.reservedQuantity}',
                            style: PharmaConnectTypography.micro,
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
