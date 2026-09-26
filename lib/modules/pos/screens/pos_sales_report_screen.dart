import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/pos_provider.dart';

class POSSalesReportScreen extends StatefulWidget {
  const POSSalesReportScreen({super.key});

  @override
  State<POSSalesReportScreen> createState() => _POSSalesReportScreenState();
}

class _POSSalesReportScreenState extends State<POSSalesReportScreen> {
  String _period = 'day'; // day, week, month, year
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<POSProvider>();
    final (start, end) = _getPeriodRange();
    provider.loadSales(
      pharmacyId: 'default_pharmacy',
      fromDate: start,
      toDate: end,
    );
  }

  (DateTime, DateTime) _getPeriodRange() {
    final now = DateTime.now();
    switch (_period) {
      case 'day':
        return (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (DateTime(start.year, start.month, start.day), now);
      case 'month':
        return (DateTime(now.year, now.month, 1), now);
      case 'year':
        return (DateTime(now.year, 1, 1), now);
      default:
        return (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();

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
                    '📊 Rapport de vente',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Export PDF
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

            // Period selector
            _buildPeriodSelector(),
            const SizedBox(height: 16),

            // Summary cards
            _buildReportSummary(provider),
            const SizedBox(height: 16),

            // Chart
            Expanded(
              flex: 2,
              child: GlassCard(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.sales.isEmpty
                    ? const Center(child: Text('Aucune donnée'))
                    : _buildSalesChart(provider),
              ),
            ),
            const SizedBox(height: 16),

            // Top products
            Expanded(child: _buildTopProducts(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text('Période:', style: PharmaConnectTypography.label),
          const SizedBox(width: 12),
          _buildPeriodChip('Jour', 'day'),
          _buildPeriodChip('Semaine', 'week'),
          _buildPeriodChip('Mois', 'month'),
          _buildPeriodChip('Année', 'year'),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: PharmaConnectColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadData();
            },
          ),
          Text(
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: PharmaConnectTypography.body2,
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: PharmaConnectColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _period == value;
    return GestureDetector(
      onTap: () {
        setState(() => _period = value);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? PharmaConnectColors.accentCyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? PharmaConnectColors.accentCyan : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? PharmaConnectColors.accentCyan
                : PharmaConnectColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildReportSummary(POSProvider provider) {
    final completedSales = provider.sales
        .where((s) => s.status == 'completed')
        .toList();
    final total = completedSales.fold<int>(0, (sum, s) => sum + s.finalAmount);
    final avgTicket = completedSales.isEmpty
        ? 0
        : total / completedSales.length;
    final refunded = provider.sales.where((s) => s.status == 'refunded').length;

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text('CA total', style: PharmaConnectTypography.micro),
                Text(
                  CurrencyFormatter.format(total),
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
                Text('Ventes', style: PharmaConnectTypography.micro),
                Text(
                  '${completedSales.length}',
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
                Text('Panier moyen', style: PharmaConnectTypography.micro),
                Text(
                  CurrencyFormatter.format(avgTicket),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PharmaConnectColors.accentPurple,
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
                Text('Remboursements', style: PharmaConnectTypography.micro),
                Text(
                  '$refunded',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: refunded > 0
                        ? PharmaConnectColors.accentOrange
                        : PharmaConnectColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesChart(POSProvider provider) {
    // Group sales by day
    final dailySales = <DateTime, int>{};
    for (final sale in provider.sales) {
      if (sale.status != 'completed') continue;
      final date = DateTime(
        sale.createdAt.year,
        sale.createdAt.month,
        sale.createdAt.day,
      );
      dailySales[date] = (dailySales[date] ?? 0) + sale.finalAmount;
    }

    final sortedDates = dailySales.keys.toList()..sort();
    if (sortedDates.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    final maxValue = dailySales.values
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final spots = sortedDates.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        dailySales[entry.value]?.toDouble() ?? 0,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Évolution des ventes',
          style: PharmaConnectTypography.label,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= sortedDates.length)
                        return const SizedBox.shrink();
                      final date = sortedDates[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: spots.length.toDouble() - 1,
              minY: 0,
              maxY: maxValue * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: PharmaConnectColors.accentCyan,
                  barWidth: 2,
                  belowBarData: BarAreaData(
                    show: true,
                    color: PharmaConnectColors.accentCyan.withValues(
                      alpha: 0.1,
                    ),
                  ),
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProducts(POSProvider provider) {
    // Aggregate products from all sales
    final productSales = <String, int>{};
    for (final sale in provider.sales) {
      if (sale.status != 'completed' || sale.items == null) continue;
      for (final item in sale.items!) {
        productSales[item.productName] =
            (productSales[item.productName] ?? 0) + item.quantity;
      }
    }

    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedProducts.isEmpty) {
      return const Center(child: Text('Aucun produit vendu'));
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Top produits',
            style: PharmaConnectTypography.heading3,
          ),
          const SizedBox(height: 8),
          ...sortedProducts.take(5).map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    entry.key,
                    style: PharmaConnectTypography.body2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value} vendus',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: PharmaConnectColors.accentCyan,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
