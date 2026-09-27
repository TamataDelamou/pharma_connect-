import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/pos_provider.dart';
import '../../stock/providers/stock_provider.dart';

class POSInventoryScreen extends StatefulWidget {
  const POSInventoryScreen({super.key});

  @override
  State<POSInventoryScreen> createState() => _POSInventoryScreenState();
}

class _POSInventoryScreenState extends State<POSInventoryScreen> {
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // In production, load from StockProvider with pharmacy_id
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '📦 Inventaire',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Export inventory
                  },
                  icon: const Icon(Icons.file_download),
                  label: const Text('Exporter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentPurple,
                    foregroundColor: PharmaConnectColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary
            _buildInventorySummary(),
            const SizedBox(height: 16),

            // Search and filters
            _buildSearchAndFilters(),
            const SizedBox(height: 16),

            // Inventory list
            Expanded(child: _buildInventoryList()),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySummary() {
    // Mock data - in production, use StockProvider
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text('Total produits', style: PharmaConnectTypography.micro),
                Text(
                  '156',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PharmaConnectColors.accentCyan,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text('Valeur stock', style: PharmaConnectTypography.micro),
                Text(
                  CurrencyFormatter.format(2450000),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PharmaConnectColors.accentGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text('Alerte stock bas', style: PharmaConnectTypography.micro),
                Text(
                  '12',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PharmaConnectColors.accentOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _filterType,
            dropdownColor: PharmaConnectColors.primaryDeep,
            style: const TextStyle(color: PharmaConnectColors.textPrimary),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tous')),
              DropdownMenuItem(value: 'low_stock', child: Text('Stock bas')),
              DropdownMenuItem(value: 'out_of_stock', child: Text('Rupture')),
              DropdownMenuItem(value: 'in_stock', child: Text('En stock')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _filterType = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    // Mock data - in production, use StockProvider
    final mockItems = [
      {
        'name': 'Doliprane 1000mg',
        'stock': 45,
        'price': 5000,
        'status': 'in_stock',
      },
      {
        'name': 'Amoxicilline 500mg',
        'stock': 3,
        'price': 7500,
        'status': 'low_stock',
      },
      {
        'name': 'Efferalgan 500mg',
        'stock': 0,
        'price': 4500,
        'status': 'out_of_stock',
      },
      {
        'name': 'Ibuprofène 400mg',
        'stock': 12,
        'price': 6000,
        'status': 'in_stock',
      },
      {
        'name': 'Ventoline 100µg',
        'stock': 8,
        'price': 12000,
        'status': 'in_stock',
      },
      {
        'name': 'Paracétamol 500mg',
        'stock': 25,
        'price': 3500,
        'status': 'in_stock',
      },
      {
        'name': 'Spasfon 80mg',
        'stock': 2,
        'price': 8000,
        'status': 'low_stock',
      },
      {
        'name': 'Metformine 850mg',
        'stock': 0,
        'price': 6000,
        'status': 'out_of_stock',
      },
    ];

    var filtered = mockItems;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) => (item['name']?.toString() ?? '').toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }
    if (_filterType != 'all') {
      filtered = filtered
          .where((item) => item['status'] == _filterType)
          .toList();
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'Aucun produit trouvé',
          style: PharmaConnectTypography.body2,
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final stock = item['stock'] as int;
        final status = item['status'] as String;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: status == 'in_stock'
                        ? PharmaConnectColors.accentGreen
                        : status == 'low_stock'
                        ? PharmaConnectColors.accentOrange
                        : PharmaConnectColors.accentRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']?.toString() ?? '',
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Stock: $stock',
                            style: TextStyle(
                              color: status == 'in_stock'
                                  ? PharmaConnectColors.accentGreen
                                  : status == 'low_stock'
                                  ? PharmaConnectColors.accentOrange
                                  : PharmaConnectColors.accentRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyFormatter.format(item['price'] as int),
                            style: PharmaConnectTypography.micro,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'in_stock'
                        ? PharmaConnectColors.accentGreen.withValues(
                            alpha: 0.15,
                          )
                        : status == 'low_stock'
                        ? PharmaConnectColors.accentOrange.withValues(
                            alpha: 0.15,
                          )
                        : PharmaConnectColors.accentRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status == 'in_stock'
                        ? 'En stock'
                        : status == 'low_stock'
                        ? 'Stock bas'
                        : 'Rupture',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: status == 'in_stock'
                          ? PharmaConnectColors.accentGreen
                          : status == 'low_stock'
                          ? PharmaConnectColors.accentOrange
                          : PharmaConnectColors.accentRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
