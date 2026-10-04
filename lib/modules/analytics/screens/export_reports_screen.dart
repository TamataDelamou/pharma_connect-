import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/export_service.dart';
import '../providers/analytics_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

/// Audit Module 28 (BI), Étape 3 (05/09/2026), BI-8 : livrable demandé
/// explicitement par le porteur du projet ("écran d'exportation de rapports
/// anonymisés"), absent avant ce correctif — `ExportService`
/// (core/utils/export_service.dart) existait déjà mais n'était utilisé nulle
/// part dans ce module.
///
/// Les 3 exports ci-dessous ne lisent que les données déjà chargées par
/// `AnalyticsProvider`, elles-mêmes issues des vues "_scoped" / de
/// `get_pharmacy_daily_stats()` (BI-1/BI-2) : jamais de ligne nominative de
/// patient, jamais de donnée de santé — uniquement des totaux/compteurs par
/// officine ou par produit, déjà filtrés au rôle du compte courant avant
/// même d'atteindre cet écran. "Anonymisé" tient donc à la nature des
/// indicateurs BI eux-mêmes, pas à un traitement supplémentaire appliqué ici.
class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({super.key});

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  bool _isExporting = false;
  String? _lastExportLabel;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      if (provider.pharmacyPerformance.isEmpty &&
          provider.topProducts.isEmpty &&
          provider.dailyStats.isEmpty) {
        provider.loadAllData();
      }
    });
  }

  Future<void> _export(String label, Future<String> Function() build) async {
    setState(() {
      _isExporting = true;
      _error = null;
      _lastExportLabel = null;
    });
    try {
      final path = await build();
      await ExportService.shareFile(path);
      if (!mounted) return;
      setState(() => _lastExportLabel = label);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Échec de l\'export « $label » : $e');
    }
    if (!mounted) return;
    setState(() => _isExporting = false);
  }

  Future<String> _exportPharmacies(AnalyticsProvider provider) {
    const headers = [
      'Officine',
      'Réservations',
      'Livraisons',
      'Transactions',
      'Chiffre d\'affaires',
    ];
    final rows = provider.pharmacyPerformance
        .map(
          (p) => [
            p.name,
            p.totalReservations,
            p.totalDeliveries,
            p.totalTransactions,
            p.totalRevenue,
          ],
        )
        .toList();
    return ExportService.exportToCsv(rows, headers);
  }

  Future<String> _exportDailyStats(AnalyticsProvider provider) {
    const headers = [
      'Date',
      'Consultations',
      'Prescriptions',
      'Réservations',
      'Livraisons',
      'Transactions',
      'Chiffre d\'affaires',
    ];
    final rows = provider.dailyStats
        .map(
          (d) => [
            '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}',
            d.consultationsCount,
            d.prescriptionsCount,
            d.reservationsCount,
            d.deliveriesCount,
            d.transactionsCount,
            d.revenue,
          ],
        )
        .toList();
    return ExportService.exportToCsv(rows, headers);
  }

  Future<String> _exportTopProducts(AnalyticsProvider provider) {
    const headers = [
      'Produit',
      'DCI',
      'Quantité vendue',
      'Prix moyen',
      'Officines en stock',
    ];
    final rows = provider.topProducts
        .map(
          (p) => [
            p.name,
            p.genericName,
            p.totalQuantitySold,
            p.avgPrice,
            p.pharmaciesWithStock,
          ],
        )
        .toList();
    return ExportService.exportToCsv(rows, headers);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📤 Export de rapports',
                        style: context.text.heading2,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Rapports agrégés (CSV), sans donnée nominative de patient',
                        style: context.text.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: context.text.body2.copyWith(
                    color: context.palette.danger,
                  ),
                ),
              ),
            if (_lastExportLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Export « $_lastExportLabel » prêt à partager.',
                  style: context.text.body2.copyWith(
                    color: context.palette.success,
                  ),
                ),
              ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        _buildExportCard(
                          icon: '🏥',
                          title: 'Performance des officines',
                          subtitle:
                              '${provider.pharmacyPerformance.length} officine(s) accessible(s) à votre compte',
                          onExport: () => _export(
                            'Performance des officines',
                            () => _exportPharmacies(provider),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildExportCard(
                          icon: '📈',
                          title: 'Activité quotidienne',
                          subtitle:
                              '${provider.dailyStats.length} jour(s) sur la période accessible',
                          onExport: () => _export(
                            'Activité quotidienne',
                            () => _exportDailyStats(provider),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildExportCard(
                          icon: '💊',
                          title: 'Top produits',
                          subtitle: '${provider.topProducts.length} produit(s)',
                          onExport: () => _export(
                            'Top produits',
                            () => _exportTopProducts(provider),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onExport,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: context.text.micro.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : onExport,
            icon: _isExporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share, size: 16),
            label: const Text('Exporter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.primary,
              foregroundColor: context.palette.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
