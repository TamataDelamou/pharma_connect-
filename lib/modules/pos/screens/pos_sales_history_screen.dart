import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/pos_provider.dart';
import '../models/pos_sale.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class POSSalesHistoryScreen extends StatefulWidget {
  const POSSalesHistoryScreen({super.key});

  @override
  State<POSSalesHistoryScreen> createState() => _POSSalesHistoryScreenState();
}

class _POSSalesHistoryScreenState extends State<POSSalesHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSales();
    });
  }

  void _loadSales() {
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) return;
    final provider = context.read<POSProvider>();
    provider.loadSales(
      pharmacyId: pharmacyId,
      status: _selectedStatus,
      fromDate: _startDate,
      toDate: _endDate,
    );
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
                      '📋 Historique des ventes',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 16),

            // Filters
            _buildFilters(provider),
            const SizedBox(height: 16),

            // Summary
            _buildSummary(provider),
            const SizedBox(height: 16),

            // Sales list
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(child: Text(provider.error!))
                  : provider.sales.isEmpty
                  ? Center(
                      child: Text('Aucune vente', style: context.text.body2),
                    )
                  : ListView.builder(
                      itemCount: provider.sales.length,
                      itemBuilder: (context, index) {
                        final sale = provider.sales[index];
                        return _buildSaleCard(sale);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(POSProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Start date
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: context.palette.primary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() => _startDate = date);
                  _loadSales();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: context.palette.veil(0.24)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Début',
                      style: context.text.body2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // End date
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: context.palette.primary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() => _endDate = date);
                  _loadSales();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: context.palette.veil(0.24)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'Fin',
                      style: context.text.body2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Status filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              hint: const Text('Statut'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous')),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text('✅ Terminées'),
                ),
                DropdownMenuItem(
                  value: 'refunded',
                  child: Text('🔄 Remboursées'),
                ),
                DropdownMenuItem(value: 'cancelled', child: Text('❌ Annulées')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                _loadSales();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Refresh
          IconButton(
            icon: Icon(Icons.refresh, color: context.palette.textSecondary),
            onPressed: _loadSales,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(POSProvider provider) {
    final totalSales = provider.sales
        .where((s) => s.status == 'completed')
        .length;
    final totalRevenue = provider.sales
        .where((s) => s.status == 'completed')
        .fold<int>(0, (sum, s) => sum + s.finalAmount);

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('Total ventes', style: context.text.micro),
                Text(
                  '$totalSales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.palette.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: context.palette.veil(0.12)),
          Expanded(
            child: Column(
              children: [
                Text('CA total', style: context.text.micro),
                Text(
                  CurrencyFormatter.format(totalRevenue),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.palette.success,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: context.palette.veil(0.12)),
          Expanded(
            child: Column(
              children: [
                Text('Remboursements', style: context.text.micro),
                Text(
                  '${provider.sales.where((s) => s.status == 'refunded').length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.palette.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(POSSale sale) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        onTap: () => context.push('/pos/receipt/${sale.id}'),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: sale.status == 'completed'
                    ? context.palette.success
                    : sale.status == 'refunded'
                    ? context.palette.warning
                    : context.palette.danger,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sale.saleNumber,
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(sale.paymentLabel, style: context.text.micro),
                      const Spacer(),
                      Text(
                        sale.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: sale.status == 'completed'
                              ? context.palette.success
                              : sale.status == 'refunded'
                              ? context.palette.warning
                              : context.palette.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatDate(sale.createdAt),
                        style: context.text.micro,
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.format(sale.finalAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: context.palette.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
