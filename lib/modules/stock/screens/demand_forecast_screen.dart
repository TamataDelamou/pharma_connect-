import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/forecast_provider.dart';
import '../providers/stock_provider.dart';
import '../widgets/forecast_chart.dart';

/// Écran « Détail des prévisions par produit » (cahier, Module 11 — IA).
///
/// Audit Module 11 (29/08/2026) : ce fichier existait déjà sous
/// `lib/modules/stock/` (contredisant le registre D5 « dossier IA
/// inexistant »), routé (`/stock/forecast`) et son provider déjà déclaré
/// dans `app.dart`, mais entièrement non fonctionnel : `pharmacyId` était
/// confondu avec l'ID utilisateur (`SupabaseService().currentUser?.id`,
/// jamais égal à `pharmacies.id` — toute requête scopée par officine
/// retournait donc systématiquement zéro ligne), et le sélecteur de produit
/// était une liste de 5 produits fictifs codés en dur (`p1`..`p5`), sans
/// lien avec le catalogue réel. Corrigé : `AuthProvider.pharmacyId` (même
/// patron que `alert_threshold_settings_screen.dart`, Module 10) + sélecteur
/// alimenté par le stock réel de l'officine (`StockProvider`).
class DemandForecastScreen extends StatefulWidget {
  final String? productId;

  const DemandForecastScreen({super.key, this.productId});

  @override
  State<DemandForecastScreen> createState() => _DemandForecastScreenState();
}

class _DemandForecastScreenState extends State<DemandForecastScreen> {
  String? _selectedProductId;
  int _forecastDays = 14;

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
    context.read<StockProvider>().loadStock(pharmacyId: pharmacyId);
    context.read<StockForecastProvider>().checkAlerts(pharmacyId);
    if (widget.productId != null) {
      _selectedProductId = widget.productId;
      _generateForecast();
    }
  }

  void _generateForecast() {
    if (_selectedProductId == null) return;
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) return;
    context.read<StockForecastProvider>().generateForecasts(
      productId: _selectedProductId!,
      pharmacyId: pharmacyId,
      days: _forecastDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<StockForecastProvider>();

    final isPharmacist = auth.userRole == UserRole.pharmacien;
    final pharmacyId = auth.pharmacyId;

    if (!isPharmacist) {
      return _restrictedScaffold('Réservé aux pharmaciens de l\'officine.');
    }
    if (pharmacyId == null) {
      return _restrictedScaffold(
        'Aucune officine rattachée à ce compte pharmacien.',
      );
    }

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
                        '📊 Prévision de la demande',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Anticipez vos besoins en stock',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 4),
            // Audit Module 11 (29/08/2026) : modèle heuristique explicite —
            // moyenne des ventes des 30 derniers mouvements de type 'sale'
            // + facteur jour de semaine + bruit aléatoire, PAS un modèle de
            // saisonnalité/tendance/événements réel. Voir rapport d'audit
            // Module 11, arbitrage D18 (reporté).
            const Text(
              'Modèle indicatif (moyenne de vente récente + tendance '
              'hebdomadaire) — pas encore un moteur prédictif avancé.',
              style: PharmaConnectTypography.micro,
            ),
            if (provider.isOffline) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PharmaConnectColors.accentOrange.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 16,
                      color: PharmaConnectColors.accentOrange,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hors ligne — dernières prévisions connues affichées.',
                        style: TextStyle(
                          fontSize: 12,
                          color: PharmaConnectColors.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Controls
            Row(
              children: [
                Expanded(child: _buildProductSelector(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildDaysSelector()),
                const SizedBox(width: 12),
                PrimaryButton(
                  label: provider.isGenerating ? 'Génération...' : 'Générer',
                  isLoading: provider.isGenerating,
                  onPressed: _selectedProductId != null
                      ? _generateForecast
                      : null,
                  width: 120,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alerts
            if (provider.reorderAlerts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PharmaConnectColors.accentOrange.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: PharmaConnectColors.accentOrange.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: PharmaConnectColors.accentOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${provider.reorderAlerts.length} alerte(s) de réapprovisionnement',
                        style: const TextStyle(
                          color: PharmaConnectColors.accentOrange,
                        ),
                      ),
                    ),
                    TextButton(
                      // Audit Module 11 (29/08/2026), arbitrage D17 : menait
                      // vers '/stock/alerts' (alertes de STOCK, Module 4),
                      // sans rapport avec les propositions de réapprovisionnement
                      // — corrigé vers le nouvel écran dédié.
                      onPressed: () {
                        context.push('/stock/forecast/orders');
                      },
                      child: const Text('Voir'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Forecast chart
            Expanded(
              child: provider.isGenerating || provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(
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
                            style: PharmaConnectTypography.body2.copyWith(
                              color: PharmaConnectColors.accentRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: () {
                              provider.clearError();
                              _generateForecast();
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : provider.forecasts.isEmpty
                  ? const Center(
                      child: Text(
                        'Sélectionnez un produit pour voir les prévisions',
                        style: PharmaConnectTypography.body2,
                      ),
                    )
                  : GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demande prévue sur ${_forecastDays} jours',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Confiance: ${(provider.forecasts.first.confidenceLevel * 100).toStringAsFixed(0)}%',
                            style: PharmaConnectTypography.micro,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ForecastChart(forecasts: provider.forecasts),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _restrictedScaffold(String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                message,
                style: PharmaConnectTypography.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Audit Module 11 (29/08/2026) : remplace les 5 produits fictifs codés en
  // dur (p1..p5, jamais présents dans le catalogue réel — toute génération
  // aurait échoué sur `.from('products')...single()`) par le stock réel de
  // l'officine, déjà chargé par StockProvider (même source que le reste du
  // module STK).
  Widget _buildProductSelector(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();
    final items = stockProvider.stockItems;

    if (stockProvider.isLoading && items.isEmpty) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Produit',
          border: OutlineInputBorder(),
        ),
        child: Text(
          'Aucun produit en stock',
          style: PharmaConnectTypography.body2,
        ),
      );
    }

    final validSelection =
        items.any((i) => i.product.id == _selectedProductId)
        ? _selectedProductId
        : null;

    return DropdownButtonFormField<String>(
      value: validSelection,
      decoration: const InputDecoration(
        labelText: 'Produit',
        border: OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item.product.id,
              child: Text(
                item.product.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedProductId = value;
          });
          _generateForecast();
        }
      },
    );
  }

  Widget _buildDaysSelector() {
    return DropdownButtonFormField<int>(
      value: _forecastDays,
      decoration: const InputDecoration(
        labelText: 'Période',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 7, child: Text('7 jours')),
        DropdownMenuItem(value: 14, child: Text('14 jours')),
        DropdownMenuItem(value: 30, child: Text('30 jours')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _forecastDays = value);
          _generateForecast();
        }
      },
    );
  }
}
