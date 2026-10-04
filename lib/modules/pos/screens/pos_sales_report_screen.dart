import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/pos_sale.dart';
import '../providers/pos_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

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
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) return;
    final provider = context.read<POSProvider>();
    final (start, end) = _getPeriodRange();
    provider.loadSales(pharmacyId: pharmacyId, fromDate: start, toDate: end);
    // C204 (contrôle après coup) : remboursements dont refunded_at tombe dans
    // la période, indépendamment de la date de la vente.
    provider.loadRefunds(pharmacyId: pharmacyId, fromDate: start, toDate: end);
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
    final pharmacyId = context.watch<AuthProvider>().pharmacyId;
    if (pharmacyId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Aucune officine rattachée à ce compte pharmacien.',
            style: context.text.body2,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final provider = context.watch<POSProvider>();

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
                      '📊 Rapport de vente',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                ElevatedButton.icon(
                  onPressed: () {
                    // Export PDF
                  },
                  icon: const Icon(Icons.file_download),
                  label: const Text('Exporter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.secondary,
                    foregroundColor: context.palette.onPrimary,
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
            const SizedBox(height: 16),

            // Refunds (C204)
            Expanded(child: _buildRefunds(provider)),
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
          Text('Période:', style: context.text.label),
          const SizedBox(width: 12),
          _buildPeriodChip('Jour', 'day'),
          _buildPeriodChip('Semaine', 'week'),
          _buildPeriodChip('Mois', 'month'),
          _buildPeriodChip('Année', 'year'),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: context.palette.textSecondary,
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
            style: context.text.body2,
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: context.palette.textSecondary,
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
              ? context.palette.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? context.palette.primary
                : context.palette.veil(0.24),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? context.palette.primary
                : context.palette.textSecondary,
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
                Text('CA total', style: context.text.micro),
                Text(
                  CurrencyFormatter.format(total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.palette.success,
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
                Text('Ventes', style: context.text.micro),
                Text(
                  '${completedSales.length}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.palette.primary,
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
                Text('Panier moyen', style: context.text.micro),
                Text(
                  CurrencyFormatter.format(avgTicket),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.palette.secondary,
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
                Text('Remboursements', style: context.text.micro),
                Text(
                  '$refunded',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: refunded > 0
                        ? context.palette.warning
                        : context.palette.textSecondary,
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
        Text('Évolution des ventes', style: context.text.label),
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
                          style: TextStyle(
                            fontSize: 9,
                            color: context.palette.textSecondary,
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
                  color: context.palette.primary,
                  barWidth: 2,
                  belowBarData: BarAreaData(
                    show: true,
                    color: context.palette.primary.withValues(alpha: 0.1),
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

  /// C204 : liste des remboursements de la période (motif, auteur,
  /// destination du stock). Les remboursements antérieurs à C204 n'ont pas
  /// de refunded_at et n'apparaissent donc pas ici : c'est attendu.
  Widget _buildRefunds(POSProvider provider) {
    final refunds = provider.refunds;
    final total = refunds.fold<int>(0, (sum, s) => sum + s.finalAmount);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🔄 Remboursements', style: context.text.heading3),
              const Spacer(),
              Text(
                '${refunds.length} · ${CurrencyFormatter.format(total)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: refunds.isEmpty
                      ? context.palette.textSecondary
                      : context.palette.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.isLoadingRefunds
                ? const Center(child: CircularProgressIndicator())
                : provider.refundsError != null
                ? Center(
                    child: Text(
                      provider.refundsError!,
                      style: context.text.micro,
                    ),
                  )
                : refunds.isEmpty
                ? const Center(child: Text('Aucun remboursement'))
                : ListView.separated(
                    itemCount: refunds.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: context.palette.veil(0.12), height: 12),
                    itemBuilder: (_, i) => _buildRefundRow(refunds[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundRow(POSSale sale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Vente #${sale.saleNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              CurrencyFormatter.format(sale.finalAmount),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.palette.warning,
              ),
            ),
          ],
        ),
        Text(
          'Vendue le ${_formatDateTime(sale.createdAt)} · '
          'remboursée le ${sale.refundedAt != null ? _formatDateTime(sale.refundedAt!) : '—'} '
          'par ${sale.refundedByName ?? sale.refundedBy ?? '—'}',
          style: context.text.micro,
        ),
        Text(
          'Motif : ${sale.refundReason ?? '—'} · '
          '${sale.refundStockDispositionLabel ?? '—'}',
          style: context.text.body2,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
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
          Text('🏆 Top produits', style: context.text.heading3),
          const SizedBox(height: 8),
          ...sortedProducts.take(5).map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    entry.key,
                    style: context.text.body2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value} vendus',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.palette.primary,
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
